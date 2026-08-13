import 'package:drift/drift.dart';
import 'package:features/src/database/cootrafa_database.dart';

enum TransferError {
  unauthorized,
  notFound,
  inactiveParty,
  selfTransfer,
  invalidAmount,
  insufficientFunds,
  concurrentChange,
  unsupportedAction,
  storageFailure,
}

enum ReceiptAction { mutate, delete, export, share }

final class TransferResult<T> {
  const TransferResult.ok(this.value) : error = null;
  const TransferResult.failure(this.error) : value = null;
  final T? value;
  final TransferError? error;
}

final class TransferCommand {
  const TransferCommand(
    this.actorId,
    this.originId,
    this.destinationId,
    this.amountCop,
    this.description,
  );
  final int actorId, originId, destinationId, amountCop;
  final String? description;
}

final class TransferReceipt {
  const TransferReceipt({
    required this.id,
    required this.originUserId,
    required this.destinationUserId,
    required this.amountCop,
    required this.status,
    required this.description,
    required this.createdAt,
    required this.originSnapshot,
    required this.destinationSnapshot,
  });
  final String id, status, originSnapshot, destinationSnapshot;
  final int originUserId, destinationUserId, amountCop, createdAt;
  final String? description;

  @override
  bool operator ==(Object other) =>
      other is TransferReceipt &&
      id == other.id &&
      originUserId == other.originUserId &&
      destinationUserId == other.destinationUserId &&
      amountCop == other.amountCop &&
      status == other.status &&
      description == other.description &&
      createdAt == other.createdAt &&
      originSnapshot == other.originSnapshot &&
      destinationSnapshot == other.destinationSnapshot;

  @override
  int get hashCode => Object.hash(
    id,
    originUserId,
    destinationUserId,
    amountCop,
    status,
    description,
    createdAt,
    originSnapshot,
    destinationSnapshot,
  );
}

final class TransferService {
  TransferService(
    this._database, {
    required this.idGenerator,
    DateTime Function()? clock,
    this.afterRead,
  }) : _clock = clock ?? DateTime.now;
  final CootrafaDatabase _database;
  final String Function() idGenerator;
  final DateTime Function() _clock;
  final Future<void> Function()? afterRead;

  Future<TransferResult<TransferReceipt>> execute(
    TransferCommand command,
  ) => _guard(
    () => _database.transaction(() async {
      if (command.amountCop <= 0) return _fail(TransferError.invalidAmount);
      if (command.originId == command.destinationId) {
        return _fail(TransferError.selfTransfer);
      }
      final actor = await _user(command.actorId);
      if (actor == null || actor.read<String>('status') != 'active') {
        return _fail(TransferError.unauthorized);
      }
      final origin = await _user(command.originId);
      final destination = await _user(command.destinationId);
      if (origin == null || destination == null) {
        return _fail(TransferError.notFound);
      }
      if (origin.read<String>('status') != 'active' ||
          destination.read<String>('status') != 'active') {
        return _fail(TransferError.inactiveParty);
      }
      if (actor.read<String>('role') != 'admin' &&
          command.actorId != command.originId) {
        return _fail(TransferError.unauthorized);
      }
      if (origin.read<int>('balance_cop') < command.amountCop) {
        return _fail(TransferError.insufficientFunds);
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
        throw const _ConcurrentChange();
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
          command.description,
          createdAt,
          _snapshot(origin),
          _snapshot(destination),
        ],
      );
      final row = await _receiptRow(id);
      if (row == null) throw StateError('Inserted transfer is unreadable.');
      return TransferResult.ok(_receipt(row));
    }),
  );

  Future<TransferResult<TransferReceipt>> receipt(String id) =>
      _guard(() async {
        final row = await _receiptRow(id);
        return row == null
            ? _fail(TransferError.notFound)
            : TransferResult.ok(_receipt(row));
      });

  Future<TransferResult<void>> requestReceiptAction(
    String id,
    ReceiptAction action,
  ) async => const TransferResult.failure(TransferError.unsupportedAction);

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
  TransferResult<T> _fail<T>(TransferError error) =>
      TransferResult.failure(error);
  Future<TransferResult<T>> _guard<T>(
    Future<TransferResult<T>> Function() action,
  ) async {
    try {
      return await action();
    } on _ConcurrentChange {
      return const TransferResult.failure(TransferError.concurrentChange);
    } on Object {
      return const TransferResult.failure(TransferError.storageFailure);
    }
  }
}

final class _ConcurrentChange implements Exception {
  const _ConcurrentChange();
}
