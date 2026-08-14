import 'package:cotrafa_database/cotrafa_database.dart';
import 'package:core/errors/error.dart';
import 'package:drift/drift.dart';
import 'package:feature_transfer/domain/entities/receipt_action.dart';
import 'package:feature_transfer/domain/entities/transfer_command.dart';
import 'package:feature_transfer/domain/entities/transfer_party.dart';
import 'package:feature_transfer/domain/entities/transfer_receipt.dart';
import 'package:injectable/injectable.dart';

abstract interface class ITransferLocalDatasource {
  Future<List<TransferParty>> listParties(int actorUserId);
  Future<List<TransferReceipt>> listTransfers(int actorUserId);
  Future<TransferReceipt> createTransfer(TransferCommand command);
  Future<TransferReceipt> getReceipt(String id);
  Future<void> requestReceiptAction(String id, ReceiptAction action);
}

@LazySingleton(as: ITransferLocalDatasource)
final class TransferLocalDatasource implements ITransferLocalDatasource {
  TransferLocalDatasource(this._database)
    : idGenerator = _generateTransferId,
      _clock = DateTime.now,
      afterRead = null;

  TransferLocalDatasource.forTesting(
    this._database, {
    required this.idGenerator,
    DateTime Function()? clock,
    this.afterRead,
  }) : _clock = clock ?? DateTime.now;

  final CotrafaDatabase _database;
  final String Function() idGenerator;
  final DateTime Function() _clock;
  final Future<void> Function()? afterRead;

  static String _generateTransferId() =>
      DateTime.now().microsecondsSinceEpoch.toRadixString(36);

  @override
  Future<List<TransferParty>> listParties(int actorUserId) async {
    final actor = await _user(actorUserId);
    if (actor == null || actor.read<String>('status') != 'active') {
      throw const UnauthorizedException();
    }
    final rows = await _database
        .customSelect(
          'SELECT id,email,full_name,balance_cop FROM users '
          "WHERE status='active' ORDER BY full_name,email",
        )
        .get();
    return rows.map(_party).toList();
  }

  @override
  Future<List<TransferReceipt>> listTransfers(int actorUserId) async {
    final actor = await _user(actorUserId);
    if (actor == null || actor.read<String>('status') != 'active') {
      throw const UnauthorizedException();
    }
    final isAdmin = actor.read<String>('role') == 'admin';
    final rows = await _database
        .customSelect(
          isAdmin
              ? 'SELECT * FROM transfers ORDER BY created_at DESC, id DESC'
              : 'SELECT * FROM transfers '
                    'WHERE origin_user_id=? OR destination_user_id=? '
                    'ORDER BY created_at DESC, id DESC',
          variables: isAdmin
              ? const <Variable<Object>>[]
              : <Variable<Object>>[
                  Variable<int>(actorUserId),
                  Variable<int>(actorUserId),
                ],
        )
        .get();
    return rows.map(_receipt).toList();
  }

  @override
  Future<TransferReceipt> createTransfer(
    TransferCommand command,
  ) => _database.transaction(() async {
    _validateCommand(command);
    final actor = await _user(command.actorId);
    if (actor == null || actor.read<String>('status') != 'active') {
      throw const UnauthorizedException();
    }
    final origin = await _user(command.originId);
    final destination = await _user(command.destinationId);
    if (origin == null || destination == null) {
      throw const NotFoundException();
    }
    if (origin.read<String>('status') != 'active' ||
        destination.read<String>('status') != 'active') {
      throw const ValidationException(
        message: 'Both transfer users must be active.',
      );
    }
    if (actor.read<String>('role') != 'admin' &&
        command.actorId != command.originId) {
      throw const UnauthorizedException();
    }
    if (origin.read<int>('balance_cop') < command.amountCop) {
      throw const ValidationException(message: 'Insufficient balance.');
    }

    await afterRead?.call();
    final debit = await _database.customUpdate(
      "UPDATE users SET balance_cop=balance_cop-? WHERE id=? AND status='active' AND balance_cop>=?",
      variables: <Variable<Object>>[
        Variable<int>(command.amountCop),
        Variable<int>(command.originId),
        Variable<int>(command.amountCop),
      ],
      updates: <TableInfo<Table, Object?>>{_database.users},
    );
    final credit = await _database.customUpdate(
      "UPDATE users SET balance_cop=balance_cop+? WHERE id=? AND status='active'",
      variables: <Variable<Object>>[
        Variable<int>(command.amountCop),
        Variable<int>(command.destinationId),
      ],
      updates: <TableInfo<Table, Object?>>{_database.users},
    );
    if (debit != 1 || credit != 1) {
      throw const StorageException(
        message: 'Concurrent balance change detected.',
      );
    }

    final id = idGenerator();
    final createdAt = _clock().millisecondsSinceEpoch;
    await _database.customStatement(
      'INSERT INTO transfers VALUES (?,?,?,?,?,?,?,?,?)',
      <Object?>[
        id,
        command.originId,
        command.destinationId,
        command.amountCop,
        'completed',
        _optional(command.description),
        createdAt,
        _snapshot(origin),
        _snapshot(destination),
      ],
    );
    final row = await _receiptRow(id);
    if (row == null) {
      throw const StorageException(
        message: 'Inserted transfer receipt is unreadable.',
      );
    }
    return _receipt(row);
  });

  @override
  Future<TransferReceipt> getReceipt(String id) async {
    final row = await _receiptRow(id);
    if (row == null) throw const NotFoundException();
    return _receipt(row);
  }

  @override
  Future<void> requestReceiptAction(String id, ReceiptAction action) async {
    throw const ValidationException(
      message: 'Transfer receipts are read-only.',
    );
  }

  void _validateCommand(TransferCommand command) {
    if (command.amountCop <= 0) {
      throw const ValidationException(
        message: 'Transfer amount must be greater than zero.',
      );
    }
    if (command.originId == command.destinationId) {
      throw const ValidationException(
        message: 'Origin and destination must be different.',
      );
    }
  }

  Future<QueryRow?> _user(int id) => _database
      .customSelect(
        'SELECT id,email,full_name,role,status,balance_cop FROM users WHERE id=?',
        variables: <Variable<Object>>[Variable<int>(id)],
      )
      .getSingleOrNull();

  Future<QueryRow?> _receiptRow(String id) => _database
      .customSelect(
        'SELECT * FROM transfers WHERE id=?',
        variables: <Variable<Object>>[Variable<String>(id)],
      )
      .getSingleOrNull();

  TransferParty _party(QueryRow row) => TransferParty(
    id: row.read<int>('id'),
    fullName: row.read<String>('full_name'),
    email: row.read<String>('email'),
    balanceCop: row.read<int>('balance_cop'),
  );

  String _snapshot(QueryRow row) =>
      '${row.read<String>('full_name')} <${row.read<String>('email')}>';

  TransferReceipt _receipt(QueryRow row) => TransferReceipt(
    id: row.read<String>('id'),
    originUserId: row.read<int>('origin_user_id'),
    destinationUserId: row.read<int>('destination_user_id'),
    amountCop: row.read<int>('amount_cop'),
    status: row.read<String>('status'),
    description: row.readNullable<String>('description'),
    createdAt: row.read<int>('created_at'),
    originSnapshot: row.read<String>('origin_snapshot'),
    destinationSnapshot: row.read<String>('destination_snapshot'),
  );

  String? _optional(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
