import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> showActivationCodeDialog(
  BuildContext context, {
  required String code,
  required VoidCallback onCopied,
}) => showDialog<void>(
  context: context,
  builder: (dialogContext) => AlertDialog(
    title: Text('user.activation_code.title'.tr()),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('user.activation_code.instructions'.tr()),
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
          onCopied();
        },
        icon: const Icon(Icons.copy_outlined),
        label: Text('common.copy'.tr()),
      ),
      FilledButton(
        onPressed: () => Navigator.of(dialogContext).pop(),
        child: Text('common.done'.tr()),
      ),
    ],
  ),
);
