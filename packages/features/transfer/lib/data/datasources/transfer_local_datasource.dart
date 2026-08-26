import 'package:cotrafa_database/cotrafa_database.dart';
import 'package:core/errors/error.dart';
import 'package:drift/drift.dart';
import 'package:feature_transfer/domain/entities/transfer_command.dart';
import 'package:feature_transfer/domain/entities/transfer_party.dart';
import 'package:feature_transfer/domain/entities/transfer_receipt.dart';
import 'package:injectable/injectable.dart';

abstract interface class ITransferLocalDatasource {
  Future<List<TransferParty>> listParties(int actorUserId);
  Future<List<TransferReceipt>> listTransfers(int actorUserId);
  Future<TransferReceipt> createTransfer(TransferCommand command);
  Future<TransferReceipt> getReceipt(String id);
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
    if (actor == null || actor.status != 'active') {
      throw const UnauthorizedException();
    }
    final rows =
        await (_database.select(_database.users)
              ..where((table) => table.status.equals('active'))
              ..orderBy([
                (table) => OrderingTerm.asc(table.fullName),
                (table) => OrderingTerm.asc(table.email),
              ]))
            .get();
    return rows.map(_party).toList();
  }

  @override
  Future<List<TransferReceipt>> listTransfers(int actorUserId) async {
    final actor = await _user(actorUserId);
    if (actor == null || actor.status != 'active') {
      throw const UnauthorizedException();
    }
    final query = _database.select(_database.transfers);
    if (actor.role != 'admin') {
      query.where(
        (table) =>
            table.originUserId.equals(actorUserId) |
            table.destinationUserId.equals(actorUserId),
      );
    }
    query.orderBy([
      (table) => OrderingTerm.desc(table.createdAt),
      (table) => OrderingTerm.desc(table.id),
    ]);
    final rows = await query.get();
    return rows.map(_receipt).toList();
  }

  @override
  Future<TransferReceipt> createTransfer(
    TransferCommand command,
  ) => _database.transaction(() async {
    final actor = await _user(command.actorId);
    if (actor == null || actor.status != 'active') {
      throw const UnauthorizedException();
    }
    final origin = await _user(command.originId);
    final destination = await _user(command.destinationId);
    if (origin == null || destination == null) {
      throw const NotFoundException();
    }
    if (origin.status != 'active' || destination.status != 'active') {
      throw const ValidationException(
        message: 'Both transfer users must be active.',
      );
    }
    if (actor.role != 'admin' && command.actorId != command.originId) {
      throw const UnauthorizedException();
    }
    if (origin.balanceCop < command.amountCop) {
      throw const ValidationException(message: 'Insufficient balance.');
    }

    await afterRead?.call();
    final debit =
        await (_database.update(_database.users)..where(
              (table) =>
                  table.id.equals(command.originId) &
                  table.status.equals('active') &
                  table.balanceCop.isBiggerOrEqualValue(command.amountCop),
            ))
            .write(
              UsersCompanion.custom(
                balanceCop:
                    _database.users.balanceCop - Variable(command.amountCop),
              ),
            );
    final credit =
        await (_database.update(_database.users)..where(
              (table) =>
                  table.id.equals(command.destinationId) &
                  table.status.equals('active'),
            ))
            .write(
              UsersCompanion.custom(
                balanceCop:
                    _database.users.balanceCop + Variable(command.amountCop),
              ),
            );
    if (debit != 1 || credit != 1) {
      throw const StorageException(
        message: 'Concurrent balance change detected.',
      );
    }

    final id = idGenerator();
    final createdAt = _clock().millisecondsSinceEpoch;
    await _database
        .into(_database.transfers)
        .insert(
          TransfersCompanion.insert(
            id: id,
            originUserId: command.originId,
            destinationUserId: command.destinationId,
            amountCop: command.amountCop,
            status: 'completed',
            description: Value(command.description),
            createdAt: createdAt,
            originSnapshot: _snapshot(origin),
            destinationSnapshot: _snapshot(destination),
          ),
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

  Future<User?> _user(int id) => (_database.select(
    _database.users,
  )..where((table) => table.id.equals(id))).getSingleOrNull();

  Future<Transfer?> _receiptRow(String id) => (_database.select(
    _database.transfers,
  )..where((table) => table.id.equals(id))).getSingleOrNull();

  TransferParty _party(User user) => TransferParty(
    id: user.id,
    fullName: user.fullName,
    email: user.email,
    balanceCop: user.balanceCop,
  );

  String _snapshot(User user) => '${user.fullName} <${user.email}>';

  TransferReceipt _receipt(Transfer transfer) => TransferReceipt(
    id: transfer.id,
    originUserId: transfer.originUserId,
    destinationUserId: transfer.destinationUserId,
    amountCop: transfer.amountCop,
    status: transfer.status,
    description: transfer.description,
    createdAt: transfer.createdAt,
    originSnapshot: transfer.originSnapshot,
    destinationSnapshot: transfer.destinationSnapshot,
  );
}
