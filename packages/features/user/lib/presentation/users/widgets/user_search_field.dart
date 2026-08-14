import 'package:flutter/material.dart';

class UserSearchField extends StatelessWidget {
  const UserSearchField({super.key, required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => TextField(
    key: const Key('user-search-field'),
    onChanged: onChanged,
    textInputAction: TextInputAction.search,
    decoration: const InputDecoration(
      hintText: 'Buscar por nombre o correo...',
      prefixIcon: Icon(Icons.search),
    ),
  );
}
