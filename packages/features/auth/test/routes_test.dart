import 'package:feature_auth/presentation/login/view/login_view.dart';
import 'package:feature_auth/routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exposes the login route without depending on another feature', () {
    final route = loginRoute(authenticatedLocation: '/users');

    expect(route.path, LoginView.path);
    expect(route.name, LoginView.name);
  });
}
