import 'package:feature_user/presentation/users/view/user_edit_view.dart';
import 'package:feature_user/presentation/users/view/users_view.dart';
import 'package:feature_user/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  test('owns the users shell branch', () {
    final rootNavigatorKey = GlobalKey<NavigatorState>();
    final route =
        usersRoutes(
              parentNavigatorKey: rootNavigatorKey,
              actorUserId: () => 1,
              isAdmin: () => true,
              issueActivationCode: (_, _) async => null,
            ).routes.single
            as GoRoute;

    expect(route.path, UsersView.path);
    expect(route.name, UsersView.name);
    final editRoute = route.routes.single as GoRoute;
    expect(editRoute.path, UserEditView.path);
    expect(editRoute.name, UserEditView.name);
    expect(editRoute.parentNavigatorKey, same(rootNavigatorKey));
  });
}
