import 'package:core/errors/error.dart';
import 'package:core/errors/result.dart';
import 'package:feature_transfer/data/datasources/transfer_local_datasource.dart';
import 'package:feature_transfer/domain/entities/receipt_action.dart';
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
      Future<List<TransferParty>>.sync(
        () => _datasource.listParties(actorUserId),
      ).toResult(fallback: const StorageFailure());

  @override
  Future<Result<TransferReceipt>> createTransfer(TransferCommand command) =>
      Future<TransferReceipt>.sync(
        () => _datasource.createTransfer(command),
      ).toResult(fallback: const StorageFailure());

  @override
  Future<Result<TransferReceipt>> getReceipt(String id) =>
      Future<TransferReceipt>.sync(
        () => _datasource.getReceipt(id),
      ).toResult(fallback: const StorageReadFailure());

  @override
  Future<Result<void>> requestReceiptAction(String id, ReceiptAction action) =>
      Future<void>.sync(
        () => _datasource.requestReceiptAction(id, action),
      ).toResult(fallback: const StorageFailure());
}
