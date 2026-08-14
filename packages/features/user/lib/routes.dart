import 'package:feature_user/presentation/users/view/users_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final GlobalKey<NavigatorState> usersNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'users',
);

StatefulShellBranch usersRoutes({
  required int Function() actorUserId,
  required bool Function() isAdmin,
}) => StatefulShellBranch(
  navigatorKey: usersNavigatorKey,
  routes: [
    GoRoute(
      path: UsersView.path,
      name: UsersView.name,
      pageBuilder: (_, state) => NoTransitionPage(
        key: state.pageKey,
        child: UsersView.create(actorUserId: actorUserId(), isAdmin: isAdmin()),
      ),
    ),
  ],
);
