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
  ) : super(const AuthState.initial()) {
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

  Future<void> _restore(
    AuthRestoreRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    final result = await _restoreSession();
    emit(
      result.fold(
        onSuccess: (identity) => identity == null
            ? const AuthState.unauthenticated()
            : AuthState.authenticated(identity),
        onFailure: (error) => AuthState.failure(error.message),
      ),
    );
  }

  Future<void> _loginDemoAdmin(
    DemoAdminLoginRequested event,
    Emitter<AuthState> emit,
  ) => _authenticate(_loginDemoAdminUseCase.call, emit);

  Future<void> _loginClient(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) => _authenticate(() => _login(event.identifier, event.password), emit);

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
    emit,
    activation: true,
  );

  Future<void> _authenticate(
    Future<Result<AuthIdentity>> Function() request,
    Emitter<AuthState> emit, {
    bool activation = false,
  }) async {
    emit(const AuthState.loading());
    final result = await request();
    emit(
      result.fold(
        onSuccess: (identity) => activation
            ? AuthState.activationSuccess(identity)
            : AuthState.authenticated(identity),
        onFailure: (error) => AuthState.failure(error.message),
      ),
    );
  }

  Future<void> _logOut(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    final result = await _logout();
    emit(
      result.fold(
        onSuccess: (_) => const AuthState.unauthenticated(),
        onFailure: (error) => AuthState.failure(error.message),
      ),
    );
  }
}
