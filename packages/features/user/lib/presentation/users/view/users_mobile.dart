import 'package:flutter/material.dart';

class UsersMobile extends StatelessWidget {
  const UsersMobile({
    super.key,
    required this.body,
    required this.onRefresh,
    this.onCreate,
  });

  final Widget body;
  final VoidCallback onRefresh;
  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      centerTitle: false,
      title: const Text('Lista de usuarios'),
      actions: [
        IconButton(
          tooltip: 'Actualizar usuarios',
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: body,
    floatingActionButton: onCreate == null
        ? null
        : FloatingActionButton.extended(
            key: const Key('create-user-action'),
            onPressed: onCreate,
            icon: const Icon(Icons.person_add_outlined),
            label: const Text('Nuevo usuario'),
          ),
  );
}
