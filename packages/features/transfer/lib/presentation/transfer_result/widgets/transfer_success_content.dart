import 'package:easy_localization/easy_localization.dart';
import 'package:feature_transfer/domain/entities/transfer_receipt.dart';
import 'package:feature_transfer/presentation/transfer_result/widgets/transfer_receipt_card.dart';
import 'package:flutter/material.dart';

class TransferSuccessContent extends StatelessWidget {
  const TransferSuccessContent({
    required this.receipt,
    required this.maxWidth,
    required this.onHistory,
    super.key,
  });

  final TransferReceipt receipt;
  final double maxWidth;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) => Scaffold(
    key: const Key('transfer-result-success'),
    appBar: AppBar(title: Text('transfer.result.receipt_title'.tr())),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 72,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'transfer.result.success'.tr(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 24),
                TransferReceiptCard(receipt: receipt),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: onHistory,
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: Text('transfer.result.back_to_history'.tr()),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
