import 'package:easy_localization/easy_localization.dart';
import 'package:feature_user/domain/entities/user_address.dart';
import 'package:flutter/material.dart';

Future<bool> showAddressDeleteDialog(
  BuildContext context, {
  required UserAddress address,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('address.delete.title'.tr()),
        content: Text(
          address.isPrimary
              ? 'address.delete.primary_confirmation'.tr()
              : 'address.delete.confirmation'.tr(
                  namedArgs: {'address': address.line1},
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            key: const Key('confirm-delete-address'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    ) ??
    false;
