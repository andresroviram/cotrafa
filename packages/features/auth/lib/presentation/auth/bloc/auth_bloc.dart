import 'package:bloc/bloc.dart';
import 'package:core/errors/result.dart';
import 'package:feature_auth/domain/entities/auth_identity.dart';
import 'package:feature_auth/domain/usecases/auth_usecases.dart';
import 'package:feature_auth/presentation/auth/bloc/auth_event.dart';
import 'package:feature_auth/presentation/auth/bloc/auth_state.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(
    this._restoreSession,
    this._login,
    this._loginDemoAdminUseCase,
    this._activateClient,
    this._logout,
  ) : super(const AuthState()) {
    on<AuthRestoreRequested>(_restore);
    on<DemoAdminLoginRequested>(_loginDemoAdmin);
    on<AuthLoginRequested>(_loginClient);
    on<AuthActivationRequested>(_activate);
    on<AuthLogoutRequested>(_logOut);
  }

  final RestoreSession _restoreSession;
  final Login _login;
  final LoginDemoAdmin _loginDemoAdminUseCase;
  final ActivateClient _activateClient;
  final Logout _logout;

  AuthState _next(
    AuthStatus status, {
    AuthIdentity? identity,
    String? message,
  }) => state.copyWith(status: status, identity: identity, message: message);

  Future<void> _restore(
    AuthRestoreRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(_next(AuthStatus.loading));
    final result = await _restoreSession();
    emit(
      result.fold(
        onSuccess: (identity) => identity == null
            ? _next(AuthStatus.unauthenticated)
            : _next(AuthStatus.authenticated, identity: identity),
        onFailure: (_) =>
            _next(AuthStatus.failure, message: 'Unable to restore session.'),
      ),
    );
  }

  Future<void> _loginDemoAdmin(
    DemoAdminLoginRequested event,
    Emitter<AuthState> emit,
  ) => _authenticate(
    _loginDemoAdminUseCase.call,
    'Unable to sign in.',
    AuthStatus.authenticated,
    emit,
  );

  Future<void> _loginClient(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) => _authenticate(
    () => _login(event.identifier, event.password),
    'Unable to sign in.',
    AuthStatus.authenticated,
    emit,
  );

  Future<void> _activate(
    AuthActivationRequested event,
    Emitter<AuthState> emit,
  ) => _authenticate(
    () => _activateClient(
      event.email,
      event.code,
      event.username,
      event.password,
    ),
    'Unable to activate account.',
    AuthStatus.activationSuccess,
    emit,
  );

  Future<void> _authenticate(
    Future<Result<AuthIdentity>> Function() request,
    String failureMessage,
    AuthStatus successStatus,
    Emitter<AuthState> emit,
  ) async {
    emit(_next(AuthStatus.loading));
    final result = await request();
    emit(
      result.fold(
        onSuccess: (identity) => _next(successStatus, identity: identity),
        onFailure: (_) => _next(AuthStatus.failure, message: failureMessage),
      ),
    );
  }

  Future<void> _logOut(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(_next(AuthStatus.loading));
    final result = await _logout();
    emit(
      result.fold(
        onSuccess: (_) => _next(AuthStatus.unauthenticated),
        onFailure: (_) =>
            _next(AuthStatus.failure, message: 'Unable to sign out.'),
      ),
    );
  }
}
