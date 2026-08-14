import 'package:easy_localization/easy_localization.dart';
import 'package:feature_user/domain/entities/user_profile.dart';
import 'package:flutter/material.dart';

Future<bool> showUserDeleteDialog(
  BuildContext context, {
  required UserProfile user,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('user.delete.title'.tr()),
        content: Text(
          'user.delete.confirmation'.tr(namedArgs: {'name': user.displayName}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    ) ??
    false;
