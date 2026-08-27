import 'package:core/errors/error.dart';
import 'package:core/errors/result.dart';
import 'package:feature_transfer/data/datasources/transfer_local_datasource.dart';
import 'package:feature_transfer/data/models/transfer_party_model.dart';
import 'package:feature_transfer/data/models/transfer_receipt_model.dart';
import 'package:feature_transfer/domain/entities/transfer_command.dart';
import 'package:feature_transfer/domain/entities/transfer_party.dart';
import 'package:feature_transfer/domain/entities/transfer_receipt.dart';
import 'package:feature_transfer/domain/repository/i_transfer_repository.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: ITransferRepository)
final class TransferRepositoryImpl implements ITransferRepository {
  const TransferRepositoryImpl(this._datasource);

  final ITransferLocalDatasource _datasource;

  @override
  Future<Result<List<TransferParty>>> listParties(int actorUserId) =>
      Future<List<TransferPartyModel>>.sync(
            () => _datasource.listParties(actorUserId),
          )
          .then((models) => models.map((model) => model.toEntity()).toList())
          .toResult(fallback: const StorageFailure());

  @override
  Future<Result<List<TransferReceipt>>> listTransfers(int actorUserId) =>
      Future<List<TransferReceiptModel>>.sync(
            () => _datasource.listTransfers(actorUserId),
          )
          .then((models) => models.map((model) => model.toEntity()).toList())
          .toResult(fallback: const StorageReadFailure());

  @override
  Future<Result<TransferReceipt>> createTransfer(TransferCommand command) =>
      Future<TransferReceiptModel>.sync(
            () => _datasource.createTransfer(command),
          )
          .then((model) => model.toEntity())
          .toResult(fallback: const StorageFailure());

  @override
  Future<Result<TransferReceipt>> getReceipt(String id) =>
      Future<TransferReceiptModel>.sync(() => _datasource.getReceipt(id))
          .then((model) => model.toEntity())
          .toResult(fallback: const StorageReadFailure());
}
