import 'package:flutter/material.dart';

class UsersMobile extends StatelessWidget {
  const UsersMobile({super.key, required this.body, required this.onRefresh});

  final Widget body;
  final VoidCallback onRefresh;

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
  );
}
