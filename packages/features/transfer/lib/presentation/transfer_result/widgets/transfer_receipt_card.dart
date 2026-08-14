import 'package:components/localized_formatters.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feature_transfer/domain/entities/transfer_receipt.dart';
import 'package:flutter/material.dart';

class TransferReceiptCard extends StatelessWidget {
  const TransferReceiptCard({required this.receipt, super.key});

  final TransferReceipt receipt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = localizedDateTime(
      context,
      DateTime.fromMillisecondsSinceEpoch(receipt.createdAt),
    );
    return Card(
      key: const Key('transfer-receipt'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'transfer.receipt.title'.tr(),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _ReceiptRow(
              label: 'transfer.receipt.number'.tr(),
              value: receipt.id,
            ),
            _ReceiptRow(label: 'transfer.receipt.date'.tr(), value: date),
            _ReceiptRow(
              label: 'transfer.receipt.origin'.tr(),
              value: receipt.originSnapshot,
            ),
            _ReceiptRow(
              label: 'transfer.receipt.destination'.tr(),
              value: receipt.destinationSnapshot,
            ),
            _ReceiptRow(
              label: 'transfer.receipt.amount'.tr(),
              value: localizedCop(context, receipt.amountCop),
            ),
            if (receipt.description != null)
              _ReceiptRow(
                label: 'transfer.receipt.description'.tr(),
                value: receipt.description!,
              ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
          child: Text(label, style: Theme.of(context).textTheme.labelLarge),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}
