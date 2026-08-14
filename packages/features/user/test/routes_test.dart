import 'package:feature_user/presentation/users/view/users_view.dart';
import 'package:feature_user/routes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  test('owns the users shell branch', () {
    final route =
        usersRoutes(actorUserId: () => 1, isAdmin: () => true).routes.single
            as GoRoute;

    expect(route.path, UsersView.path);
    expect(route.name, UsersView.name);
  });
}
