import 'package:cotrafa_database/cotrafa_database.dart';
import 'package:core/errors/error.dart';
import 'package:drift/drift.dart';
import 'package:feature_transfer/data/datasources/mappers/transfer_database_mapper.dart';
import 'package:feature_transfer/data/models/transfer_party_model.dart';
import 'package:feature_transfer/data/models/transfer_receipt_model.dart';
import 'package:feature_transfer/domain/entities/transfer_command.dart';
import 'package:injectable/injectable.dart';

abstract interface class ITransferLocalDatasource {
  Future<List<TransferPartyModel>> listParties(int actorUserId);
  Future<List<TransferReceiptModel>> listTransfers(int actorUserId);
  Future<TransferReceiptModel> createTransfer(TransferCommand command);
  Future<TransferReceiptModel> getReceipt(String id);
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
  Future<List<TransferPartyModel>> listParties(int actorUserId) async {
    final actor = await _user(actorUserId);
    if (actor == null || actor.status != 'active') {
      throw const UnauthorizedException();
    }
    final query = _database.select(_database.users)
      ..where((table) => table.status.equals('active'))
      ..orderBy([
        (table) => OrderingTerm.asc(table.fullName),
        (table) => OrderingTerm.asc(table.email),
      ]);
    return query.map((user) => user.toTransferPartyModel()).get();
  }

  @override
  Future<List<TransferReceiptModel>> listTransfers(int actorUserId) async {
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
    return query.map((transfer) => transfer.toTransferReceiptModel()).get();
  }

  @override
  Future<TransferReceiptModel> createTransfer(
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
    final receipt = await _receiptQuery(
      id,
    ).map((transfer) => transfer.toTransferReceiptModel()).getSingleOrNull();
    if (receipt == null) {
      throw const StorageException(
        message: 'Inserted transfer receipt is unreadable.',
      );
    }
    return receipt;
  });

  @override
  Future<TransferReceiptModel> getReceipt(String id) async {
    final receipt = await _receiptQuery(
      id,
    ).map((transfer) => transfer.toTransferReceiptModel()).getSingleOrNull();
    if (receipt == null) throw const NotFoundException();
    return receipt;
  }

  Future<User?> _user(int id) => (_database.select(
    _database.users,
  )..where((table) => table.id.equals(id))).getSingleOrNull();

  Selectable<Transfer> _receiptQuery(String id) =>
      _database.select(_database.transfers)
        ..where((table) => table.id.equals(id));

  String _snapshot(User user) => '${user.fullName} <${user.email}>';
}
