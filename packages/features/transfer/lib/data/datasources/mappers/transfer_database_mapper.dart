import 'package:cotrafa_database/cotrafa_database.dart';
import 'package:feature_transfer/data/models/transfer_party_model.dart';
import 'package:feature_transfer/data/models/transfer_receipt_model.dart';

extension TransferPartyDatabaseMapper on User {
  TransferPartyModel toTransferPartyModel() => TransferPartyModel(
    id: id,
    fullName: fullName,
    email: email,
    balanceCop: balanceCop,
  );
}

extension TransferReceiptDatabaseMapper on Transfer {
  TransferReceiptModel toTransferReceiptModel() => TransferReceiptModel(
    id: id,
    originUserId: originUserId,
    destinationUserId: destinationUserId,
    amountCop: amountCop,
    status: status,
    description: description,
    createdAt: createdAt,
    originSnapshot: originSnapshot,
    destinationSnapshot: destinationSnapshot,
  );
}
