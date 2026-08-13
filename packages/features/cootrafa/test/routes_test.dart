import 'package:features/auth.dart';
import 'package:features/routes.dart';
import 'package:features/transfer.dart';
import 'package:features/user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  test('exposes the application route contract', () {
    expect(LoginView.path, '/login');
    expect(UsersView.path, '/users');
    expect(TransferView.path, '/transfer');
  });

  test('builds login and shell branch routes', () {
    expect(loginRoute.path, LoginView.path);
    expect((usersRoutes.routes.single as GoRoute).path, UsersView.path);
    expect((transferRoutes.routes.single as GoRoute).path, TransferView.path);
  });
}
