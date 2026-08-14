import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> showActivationCodeDialog(
  BuildContext context, {
  required String code,
}) => showDialog<void>(
  context: context,
  builder: (dialogContext) => AlertDialog(
    title: const Text('Código de activación'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Comparte este código con el usuario de forma segura.'),
        const SizedBox(height: 20),
        Center(
          child: SelectableText(
            code,
            key: const Key('activation-code-value'),
            style: Theme.of(dialogContext).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 6,
            ),
          ),
        ),
      ],
    ),
    actions: [
      TextButton.icon(
        key: const Key('copy-activation-code'),
        onPressed: () async {
          await Clipboard.setData(ClipboardData(text: code));
          if (!dialogContext.mounted) return;
          ScaffoldMessenger.of(
            dialogContext,
          ).showSnackBar(const SnackBar(content: Text('Código copiado')));
        },
        icon: const Icon(Icons.copy_outlined),
        label: const Text('Copiar'),
      ),
      FilledButton(
        onPressed: () => Navigator.of(dialogContext).pop(),
        child: const Text('Entendido'),
      ),
    ],
  ),
);
