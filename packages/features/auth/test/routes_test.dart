import 'package:feature_auth/presentation/activation/view/activation_view.dart';
import 'package:feature_auth/presentation/login/view/login_view.dart';
import 'package:feature_auth/routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exposes the login route without depending on another feature', () {
    final route = loginRoute(
      authenticatedLocation: '/users',
      logoAssetPath: 'assets/img/logo.png',
      logoDarkAssetPath: 'assets/img/logo_dark.png',
    );

    expect(route.path, LoginView.path);
    expect(route.name, LoginView.name);
  });

  test('exposes the client activation route', () {
    final route = activationRoute(
      authenticatedLocation: '/users',
      logoAssetPath: 'assets/img/logo.png',
      logoDarkAssetPath: 'assets/img/logo_dark.png',
    );

    expect(route.path, ActivationView.path);
    expect(route.name, ActivationView.name);
  });
}
