import 'package:feature_auth/presentation/login/view/login_view.dart';
import 'package:feature_auth/routes.dart';
import 'package:feature_transfer/presentation/transfer/view/transfer_view.dart';
import 'package:feature_transfer/routes.dart';
import 'package:feature_user/presentation/users/view/users_view.dart';
import 'package:feature_user/routes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  test('exposes the application route contract', () {
    expect(LoginView.path, '/login');
    expect(UsersView.path, '/users');
    expect(TransferView.path, '/transfer');
  });

  test('builds login and shell branch routes', () {
    expect(
      loginRoute(authenticatedLocation: UsersView.path).path,
      LoginView.path,
    );
    expect((usersRoutes.routes.single as GoRoute).path, UsersView.path);
    expect((transferRoutes.routes.single as GoRoute).path, TransferView.path);
  });
}
