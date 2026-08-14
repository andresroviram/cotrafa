import 'package:feature_user/presentation/users/activation_code_issuer.dart';
import 'package:feature_user/presentation/users/view/user_detail_view.dart';
import 'package:feature_user/presentation/users/view/user_edit_view.dart';
import 'package:feature_user/presentation/users/view/users_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final GlobalKey<NavigatorState> usersNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'users',
);

StatefulShellBranch usersRoutes({
  required GlobalKey<NavigatorState> parentNavigatorKey,
  required int Function() actorUserId,
  required bool Function() isAdmin,
  required ActivationCodeIssuer issueActivationCode,
}) => StatefulShellBranch(
  navigatorKey: usersNavigatorKey,
  routes: [
    GoRoute(
      path: UsersView.path,
      name: UsersView.name,
      pageBuilder: (_, state) => NoTransitionPage(
        key: state.pageKey,
        child: UsersView.create(
          actorUserId: actorUserId(),
          isAdmin: isAdmin(),
          issueActivationCode: issueActivationCode,
        ),
      ),
      routes: [
        GoRoute(
          path: UserDetailView.path,
          name: UserDetailView.name,
          parentNavigatorKey: parentNavigatorKey,
          builder: (_, state) => UserDetailView.create(
            actorUserId: actorUserId(),
            userId: int.tryParse(state.pathParameters['userId'] ?? '') ?? -1,
          ),
        ),
        GoRoute(
          path: UserEditView.path,
          name: UserEditView.name,
          parentNavigatorKey: parentNavigatorKey,
          builder: (_, state) => UserEditView.create(
            actorUserId: actorUserId(),
            userId: int.tryParse(state.pathParameters['userId'] ?? '') ?? -1,
          ),
        ),
      ],
    ),
  ],
);
