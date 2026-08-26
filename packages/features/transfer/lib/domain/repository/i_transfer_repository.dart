import 'package:core/errors/result.dart';
import 'package:feature_transfer/domain/entities/transfer_command.dart';
import 'package:feature_transfer/domain/entities/transfer_party.dart';
import 'package:feature_transfer/domain/entities/transfer_receipt.dart';

abstract interface class ITransferRepository {
  Future<Result<List<TransferParty>>> listParties(int actorUserId);
  Future<Result<List<TransferReceipt>>> listTransfers(int actorUserId);
  Future<Result<TransferReceipt>> createTransfer(TransferCommand command);
  Future<Result<TransferReceipt>> getReceipt(String id);
}
