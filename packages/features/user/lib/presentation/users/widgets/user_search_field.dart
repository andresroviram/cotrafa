import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class UserSearchField extends StatelessWidget {
  const UserSearchField({super.key, required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => TextField(
    key: const Key('user-search-field'),
    onChanged: onChanged,
    textInputAction: TextInputAction.search,
    decoration: InputDecoration(
      hintText: 'user.list.search_hint'.tr(),
      prefixIcon: const Icon(Icons.search),
    ),
  );
}
