import 'package:flutter/material.dart';

class UserSearchField extends StatelessWidget {
  const UserSearchField({super.key, required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      key: const Key('user-search-field'),
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Buscar por nombre o correo...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: theme.brightness == Brightness.light
            ? theme.colorScheme.surface
            : theme.colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
