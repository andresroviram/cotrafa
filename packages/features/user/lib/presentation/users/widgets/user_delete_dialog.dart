import 'package:feature_user/domain/entities/user_profile.dart';
import 'package:flutter/material.dart';

Future<bool> showUserDeleteDialog(
  BuildContext context, {
  required UserProfile user,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: Text(
          '¿Eliminar a ${user.displayName}? Si no tiene transferencias, '
          'se eliminará definitivamente. Si tiene, se desactivará para '
          'conservar el historial.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    ) ??
    false;
