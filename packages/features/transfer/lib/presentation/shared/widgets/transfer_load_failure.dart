import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class TransferLoadFailure extends StatelessWidget {
  const TransferLoadFailure({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('transfer.title'.tr())),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: Text('common.retry'.tr())),
          ],
        ),
      ),
    ),
  );
}
