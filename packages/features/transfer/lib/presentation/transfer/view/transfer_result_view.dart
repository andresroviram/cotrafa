import 'package:feature_transfer/domain/entities/transfer_receipt.dart';
import 'package:feature_transfer/presentation/transfer/widgets/transfer_failure_content.dart';
import 'package:feature_transfer/presentation/transfer/widgets/transfer_success_content.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';

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

class TransferResultView extends StatelessWidget {
  const TransferResultView({required this.outcome, super.key});

  final TransferOutcome outcome;

  static const String path = 'result';
  static const String name = 'transfer-result';

  @override
  Widget build(BuildContext context) {
    final maxWidth = ResponsiveBreakpoints.of(context).largerThan(MOBILE)
        ? 760.0
        : 600.0;
    return switch (outcome) {
      TransferSucceeded(:final receipt) => TransferSuccessContent(
        receipt: receipt,
        maxWidth: maxWidth,
        onHistory: () => context.pop(true),
      ),
      TransferFailed(:final message) => TransferFailureContent(
        message: message,
        maxWidth: maxWidth,
        onRetry: () => context.pop(false),
        onHistory: () => context.pop(true),
      ),
    };
  }
}
