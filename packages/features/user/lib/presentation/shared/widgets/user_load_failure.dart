import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class UserLoadFailure extends StatelessWidget {
  const UserLoadFailure({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('user.load_error'.tr()),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: onRetry, child: Text('common.retry'.tr())),
      ],
    ),
  );
}
