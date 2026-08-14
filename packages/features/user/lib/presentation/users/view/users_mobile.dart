import 'package:flutter/material.dart';

class UsersMobile extends StatelessWidget {
  const UsersMobile({super.key, required this.body, this.onCreate});

  final Widget body;
  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(centerTitle: false, title: const Text('Lista de usuarios')),
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
