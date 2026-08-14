import 'package:flutter/material.dart';

class TransferFailureContent extends StatelessWidget {
  const TransferFailureContent({
    required this.message,
    required this.maxWidth,
    required this.onRetry,
    required this.onHistory,
    super.key,
  });

  final String message;
  final double maxWidth;
  final VoidCallback onRetry;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      key: const Key('transfer-result-failure'),
      appBar: AppBar(title: const Text('Resultado')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.cancel, size: 72, color: theme.colorScheme.error),
                  const SizedBox(height: 16),
                  Text(
                    'Transferencia fallida',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Intentar nuevamente'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: onHistory,
                    icon: const Icon(Icons.receipt_long_outlined),
                    label: const Text('Volver al historial'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
