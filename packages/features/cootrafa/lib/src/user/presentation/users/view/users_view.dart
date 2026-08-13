import 'package:flutter/material.dart';

class UsersView extends StatelessWidget {
  const UsersView({super.key});

  static const String path = '/users';
  static const String name = 'users';

  static Widget create() => const UsersView();

  @override
  Widget build(BuildContext context) => const Center(child: Text('Usuarios'));
}
