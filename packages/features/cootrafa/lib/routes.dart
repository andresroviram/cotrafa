import 'package:features/auth.dart';
import 'package:features/transfer.dart';
import 'package:features/user.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final GlobalKey<NavigatorState> usersNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'users',
);
final GlobalKey<NavigatorState> transferNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'transfer');

GoRoute get loginRoute => GoRoute(
  path: LoginView.path,
  name: LoginView.name,
  builder: (_, _) => LoginView.create(),
);

StatefulShellBranch get usersRoutes => StatefulShellBranch(
  navigatorKey: usersNavigatorKey,
  routes: [
    GoRoute(
      path: UsersView.path,
      name: UsersView.name,
      pageBuilder: (_, state) =>
          NoTransitionPage(key: state.pageKey, child: UsersView.create()),
    ),
  ],
);

StatefulShellBranch get transferRoutes => StatefulShellBranch(
  navigatorKey: transferNavigatorKey,
  routes: [
    GoRoute(
      path: TransferView.path,
      name: TransferView.name,
      pageBuilder: (_, state) =>
          NoTransitionPage(key: state.pageKey, child: TransferView.create()),
    ),
  ],
);
