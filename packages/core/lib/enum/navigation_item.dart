import 'package:flutter/material.dart';

enum NavigationItem {
  home(iconData: Icons.dashboard_outlined),
  wishlist(iconData: Icons.favorite_border_outlined),
  settings(iconData: Icons.settings_outlined),
  funds(iconData: Icons.account_balance_wallet_outlined),
  transactions(iconData: Icons.receipt_long_outlined);

  const NavigationItem({required this.iconData});
  final IconData iconData;
  String get label => 'nav.$name';
}
