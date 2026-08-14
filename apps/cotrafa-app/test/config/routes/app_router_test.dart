import 'dart:io';

import 'package:cotrafa_app/config/routes/app_router.dart';
import 'package:feature_auth/presentation/auth/bloc/auth_bloc.dart';
import 'package:feature_auth/presentation/auth/bloc/auth_state.dart';
import 'package:feature_auth/presentation/activation/view/activation_view.dart';
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
    when(
      () => authBloc.stream,
    ).thenAnswer((_) => const Stream<AuthState>.empty());

    final router = createRouter(authBloc);

    expect(router.routeInformationProvider.value.uri.path, '/login');
    expect(router.configuration.routes, hasLength(3));
    final activation = router.configuration.routes[1] as GoRoute;
    expect(activation.name, ActivationView.name);
    final shell = router.configuration.routes.last as StatefulShellRoute;
    expect(shell.branches, hasLength(2));

    final source = File('lib/config/routes/app_router.dart').readAsStringSync();
    expect(source, contains('ScaffoldWithNavigation('));
    expect(source, isNot(contains('_AuthenticatedShell')));
  });
}
