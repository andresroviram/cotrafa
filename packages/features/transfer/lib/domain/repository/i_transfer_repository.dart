import 'package:core/errors/result.dart';
import 'package:feature_transfer/domain/entities/receipt_action.dart';
import 'package:feature_transfer/domain/entities/transfer_command.dart';
import 'package:feature_transfer/domain/entities/transfer_party.dart';
import 'package:feature_transfer/domain/entities/transfer_receipt.dart';

abstract interface class ITransferRepository {
  Future<Result<List<TransferParty>>> listParties(int actorUserId);
  Future<Result<TransferReceipt>> createTransfer(TransferCommand command);
  Future<Result<TransferReceipt>> getReceipt(String id);
  Future<Result<void>> requestReceiptAction(String id, ReceiptAction action);
}
