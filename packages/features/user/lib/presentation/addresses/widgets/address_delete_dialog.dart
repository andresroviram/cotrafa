import 'package:feature_user/domain/entities/user_address.dart';
import 'package:flutter/material.dart';

Future<bool> showAddressDeleteDialog(
  BuildContext context, {
  required UserAddress address,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar dirección'),
        content: Text(
          address.isPrimary
              ? 'Esta es la dirección principal. Si existen otras, la siguiente se marcará como principal.'
              : '¿Deseas eliminar ${address.line1}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('confirm-delete-address'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    ) ??
    false;
