import 'package:feature_transfer/domain/entities/transfer_receipt.dart';

sealed class TransferOutcome {
  const TransferOutcome();

  const factory TransferOutcome.success(TransferReceipt receipt) =
      TransferSucceeded;
  const factory TransferOutcome.failure(String message) = TransferFailed;
}

final class TransferSucceeded extends TransferOutcome {
  const TransferSucceeded(this.receipt);

  final TransferReceipt receipt;
}

final class TransferFailed extends TransferOutcome {
  const TransferFailed(this.message);

  final String message;
}
