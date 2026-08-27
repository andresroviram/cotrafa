import 'package:bloc_test/bloc_test.dart';
import 'package:core/errors/error.dart';
import 'package:core/errors/result.dart';
import 'package:feature_auth/domain/entities/auth_identity.dart';
import 'package:feature_auth/domain/usecases/auth_usecases.dart';
import 'package:feature_auth/presentation/auth/bloc/auth_bloc.dart';
import 'package:feature_auth/presentation/auth/bloc/auth_event.dart';
import 'package:feature_auth/presentation/auth/bloc/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Restore extends Mock implements RestoreSession {}

class _Login extends Mock implements Login {}

class _LoginDemoAdmin extends Mock implements LoginDemoAdmin {}

class _Activate extends Mock implements ActivateClient {}

class _Logout extends Mock implements Logout {}

void main() {
  const identity = AuthIdentity(userId: 7, role: 'client');
  const authenticatedStates = <AuthState>[
    AuthState.loading(),
    AuthState.authenticated(identity),
  ];
  const signInFailureStates = <AuthState>[
    AuthState.loading(),
    AuthState.failure('users.password_hash'),
  ];
  late _Restore restore;
  late _Login login;
  late _LoginDemoAdmin loginDemoAdmin;
  late _Activate activate;
  late _Logout logout;

  AuthBloc build() =>
      AuthBloc(restore, login, loginDemoAdmin, activate, logout);

  setUp(() {
    restore = _Restore();
    login = _Login();
    loginDemoAdmin = _LoginDemoAdmin();
    activate = _Activate();
    logout = _Logout();
  });

  test('Freezed events have value equality and generated union dispatch', () {
    const first = AuthEvent.loginRequested('client@example.com', 'secret');
    const second = AuthEvent.loginRequested('client@example.com', 'secret');
    expect(first, second);
    expect(
      first.when(
        restoreRequested: () => 'restore',
        demoAdminLoginRequested: () => 'demo',
        loginRequested: (identifier, password) => '$identifier:$password',
        activationRequested: (email, code, username, password) => 'activate',
        logoutRequested: () => 'logout',
      ),
      'client@example.com:secret',
    );
  });

  test('Freezed state has value equality and generated union dispatch', () {
    const authenticated = AuthState.authenticated(identity);
    expect(authenticated, const AuthState.authenticated(identity));
    expect(
      authenticated.when(
        initial: () => null,
        loading: () => null,
        unauthenticated: () => null,
        authenticated: (value) => value,
        activationSuccess: (value) => value,
        failure: (_) => null,
      ),
      identity,
    );
  });

  blocTest<AuthBloc, AuthState>(
    'restore authenticates an identity',
    setUp: () => when(
      restore.call,
    ).thenAnswer((_) async => const Success<AuthIdentity?>(identity)),
    build: build,
    act: (bloc) => bloc.add(const AuthEvent.restoreRequested()),
    expect: () => authenticatedStates,
  );

  blocTest<AuthBloc, AuthState>(
    'restore without a session is unauthenticated',
    setUp: () => when(
      restore.call,
    ).thenAnswer((_) async => const Success<AuthIdentity?>(null)),
    build: build,
    act: (bloc) => bloc.add(const AuthEvent.restoreRequested()),
    expect: () => const <AuthState>[
      AuthState.loading(),
      AuthState.unauthenticated(),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'restore failure exposes the Result error message',
    setUp: () => when(restore.call).thenAnswer(
      (_) async => const Error<AuthIdentity?>(
        StorageReadFailure(message: 'local_session storage details'),
      ),
    ),
    build: build,
    act: (bloc) => bloc.add(const AuthEvent.restoreRequested()),
    expect: () => const <AuthState>[
      AuthState.loading(),
      AuthState.failure('local_session storage details'),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'demo request delegates credential ownership to LoginDemoAdmin',
    setUp: () => when(
      loginDemoAdmin.call,
    ).thenAnswer((_) async => const Success(identity)),
    build: build,
    act: (bloc) => bloc.add(const AuthEvent.demoAdminLoginRequested()),
    expect: () => authenticatedStates,
    verify: (_) => verify(loginDemoAdmin.call).called(1),
  );

  blocTest<AuthBloc, AuthState>(
    'demo failure exposes the Result error message',
    setUp: () => when(loginDemoAdmin.call).thenAnswer(
      (_) async => const Error<AuthIdentity>(
        StorageFailure(message: 'users.password_hash'),
      ),
    ),
    build: build,
    act: (bloc) => bloc.add(const AuthEvent.demoAdminLoginRequested()),
    expect: () => signInFailureStates,
  );

  for (final identifier in <String>['client@example.com', 'client_name']) {
    blocTest<AuthBloc, AuthState>(
      'normal login accepts $identifier',
      setUp: () => when(
        () => login(identifier, 'secret'),
      ).thenAnswer((_) async => const Success(identity)),
      build: build,
      act: (bloc) => bloc.add(AuthEvent.loginRequested(identifier, 'secret')),
      expect: () => authenticatedStates,
    );
  }

  blocTest<AuthBloc, AuthState>(
    'login failure exposes the Result error message',
    setUp: () => when(() => login(any(), any())).thenAnswer(
      (_) async => const Error<AuthIdentity>(
        StorageFailure(message: 'users.password_hash'),
      ),
    ),
    build: build,
    act: (bloc) => bloc.add(const AuthEvent.loginRequested('client', 'wrong')),
    expect: () => signInFailureStates,
  );

  blocTest<AuthBloc, AuthState>(
    'activation succeeds with the returned identity',
    setUp: () => when(
      () => activate(any(), any(), any(), any()),
    ).thenAnswer((_) async => const Success(identity)),
    build: build,
    act: (bloc) => bloc.add(
      const AuthEvent.activationRequested(
        'client@example.com',
        '123456',
        'client',
        'secret',
      ),
    ),
    expect: () => const <AuthState>[
      AuthState.loading(),
      AuthState.activationSuccess(identity),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'activation failure exposes the Result error message',
    setUp: () => when(() => activate(any(), any(), any(), any())).thenAnswer(
      (_) async => const Error<AuthIdentity>(
        AuthFailure(message: 'activation_code_hash mismatch'),
      ),
    ),
    build: build,
    act: (bloc) => bloc.add(
      const AuthEvent.activationRequested(
        'client@example.com',
        '000000',
        'client',
        'secret',
      ),
    ),
    expect: () => const <AuthState>[
      AuthState.loading(),
      AuthState.failure('activation_code_hash mismatch'),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'logout becomes unauthenticated',
    setUp: () =>
        when(logout.call).thenAnswer((_) async => const Success<void>(null)),
    build: build,
    seed: () => const AuthState.authenticated(identity),
    act: (bloc) => bloc.add(const AuthEvent.logoutRequested()),
    expect: () => const <AuthState>[
      AuthState.loading(),
      AuthState.unauthenticated(),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'logout failure exposes the Result error message',
    setUp: () => when(logout.call).thenAnswer(
      (_) async => const Error<void>(
        StorageFailure(message: 'local_session delete failed'),
      ),
    ),
    build: build,
    act: (bloc) => bloc.add(const AuthEvent.logoutRequested()),
    expect: () => const <AuthState>[
      AuthState.loading(),
      AuthState.failure('local_session delete failed'),
    ],
  );
}
