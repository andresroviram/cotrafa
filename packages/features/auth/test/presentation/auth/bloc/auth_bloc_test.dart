import 'package:bloc_test/bloc_test.dart';
import 'package:core/errors/error.dart';
import 'package:core/errors/result.dart';
import 'package:feature_auth/domain/entities/auth_identity.dart';
import 'package:feature_auth/domain/entities/demo_credentials.dart';
import 'package:feature_auth/domain/usecases/auth_usecases.dart';
import 'package:feature_auth/presentation/auth/bloc/auth_bloc.dart';
import 'package:feature_auth/presentation/auth/bloc/auth_event.dart';
import 'package:feature_auth/presentation/auth/bloc/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Restore extends Mock implements RestoreSession {}

class _Login extends Mock implements Login {}

class _Activate extends Mock implements ActivateClient {}

class _Logout extends Mock implements Logout {}

void main() {
  const identity = AuthIdentity(userId: 7, role: 'client');
  const credentials = DemoAdmin.credentials;
  const authenticatedStates = <AuthState>[
    AuthState(status: AuthStatus.loading),
    AuthState(status: AuthStatus.authenticated, identity: identity),
  ];
  const signInFailureStates = <AuthState>[
    AuthState(status: AuthStatus.loading),
    AuthState(status: AuthStatus.failure, message: 'Unable to sign in.'),
  ];
  late _Restore restore;
  late _Login login;
  late _Activate activate;
  late _Logout logout;

  AuthBloc build() => AuthBloc(restore, login, activate, logout, credentials);

  setUp(() {
    restore = _Restore();
    login = _Login();
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

  test('Freezed state has value equality and generated copyWith', () {
    const authenticated = AuthState(identity: identity);
    expect(authenticated, const AuthState(identity: identity));
    expect(
      authenticated.copyWith(status: AuthStatus.loading, identity: null),
      const AuthState(status: AuthStatus.loading),
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
      AuthState(status: AuthStatus.loading),
      AuthState(status: AuthStatus.unauthenticated),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'restore failure exposes a safe message',
    setUp: () => when(restore.call).thenAnswer(
      (_) async => const Error<AuthIdentity?>(
        StorageReadFailure(message: 'local_session storage details'),
      ),
    ),
    build: build,
    act: (bloc) => bloc.add(const AuthEvent.restoreRequested()),
    expect: () => const <AuthState>[
      AuthState(status: AuthStatus.loading),
      AuthState(
        status: AuthStatus.failure,
        message: 'Unable to restore session.',
      ),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'demo request passes the injected credentials to Login',
    setUp: () => when(
      () => login(credentials.identifier, credentials.password),
    ).thenAnswer((_) async => const Success(identity)),
    build: build,
    act: (bloc) => bloc.add(const AuthEvent.demoAdminLoginRequested()),
    expect: () => authenticatedStates,
    verify: (_) => verify(
      () => login(credentials.identifier, credentials.password),
    ).called(1),
  );

  blocTest<AuthBloc, AuthState>(
    'demo failure does not leak infrastructure details',
    setUp: () => when(() => login(credentials.identifier, credentials.password))
        .thenAnswer(
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
    'login failure does not leak infrastructure details',
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
      AuthState(status: AuthStatus.loading),
      AuthState(status: AuthStatus.activationSuccess, identity: identity),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'activation failure exposes a safe message',
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
      AuthState(status: AuthStatus.loading),
      AuthState(
        status: AuthStatus.failure,
        message: 'Unable to activate account.',
      ),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'logout becomes unauthenticated',
    setUp: () =>
        when(logout.call).thenAnswer((_) async => const Success<void>(null)),
    build: build,
    seed: () =>
        const AuthState(status: AuthStatus.authenticated, identity: identity),
    act: (bloc) => bloc.add(const AuthEvent.logoutRequested()),
    expect: () => const <AuthState>[
      AuthState(status: AuthStatus.loading),
      AuthState(status: AuthStatus.unauthenticated),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'logout failure exposes a safe message',
    setUp: () => when(logout.call).thenAnswer(
      (_) async => const Error<void>(
        StorageFailure(message: 'local_session delete failed'),
      ),
    ),
    build: build,
    act: (bloc) => bloc.add(const AuthEvent.logoutRequested()),
    expect: () => const <AuthState>[
      AuthState(status: AuthStatus.loading),
      AuthState(status: AuthStatus.failure, message: 'Unable to sign out.'),
    ],
  );
}
