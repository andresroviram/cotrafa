import 'package:feature_transfer/domain/entities/transfer_receipt.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransferReceiptCard extends StatelessWidget {
  const TransferReceiptCard({required this.receipt, super.key});

  final TransferReceipt receipt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = NumberFormat.currency(
      locale: 'es_CO',
      symbol: r'$',
      decimalDigits: 0,
    );
    final date = DateFormat(
      'dd/MM/yyyy HH:mm',
    ).format(DateTime.fromMillisecondsSinceEpoch(receipt.createdAt));
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
                  'Comprobante',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _ReceiptRow(label: 'Número', value: receipt.id),
            _ReceiptRow(label: 'Fecha', value: date),
            _ReceiptRow(label: 'Origen', value: receipt.originSnapshot),
            _ReceiptRow(label: 'Destino', value: receipt.destinationSnapshot),
            _ReceiptRow(
              label: 'Valor',
              value: currency.format(receipt.amountCop),
            ),
            if (receipt.description != null)
              _ReceiptRow(label: 'Descripción', value: receipt.description!),
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
