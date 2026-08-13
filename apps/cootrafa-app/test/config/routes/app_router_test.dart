import 'dart:io';

import 'package:cootrafa_app/config/routes/app_router.dart';
import 'package:features/auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

final class MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  test('starts at login and exposes the authenticated shell', () {
    final authBloc = MockAuthBloc();
    when(
      () => authBloc.state,
    ).thenReturn(const AuthState(status: AuthStatus.unauthenticated));

    final router = createRouter(authBloc);

    expect(router.routeInformationProvider.value.uri.path, '/login');
    expect(router.configuration.routes, hasLength(2));
    final shell = router.configuration.routes.last as StatefulShellRoute;
    expect(shell.branches, hasLength(2));

    final source = File('lib/config/routes/app_router.dart').readAsStringSync();
    expect(source, contains('ScaffoldWithNavigation('));
    expect(source, isNot(contains('_AuthenticatedShell')));
  });
}
