import 'package:feature_auth/domain/entities/auth_identity.dart';

enum AuthError {
  unauthorized,
  clientNotPending,
  identifierTaken,
  invalidCredentials,
  storageFailure,
}

final class AuthResult<T> {
  const AuthResult.ok(this.value) : error = null;
  const AuthResult.failure(this.error) : value = null;

  final T? value;
  final AuthError? error;
}

abstract interface class IAuthLocalDatasource {
  Future<AuthResult<String>> issueActivationCode(int actorUserId, String email);

  Future<AuthResult<AuthIdentity>> activate(
    String email,
    String code,
    String username,
    String password,
  );

  Future<AuthResult<AuthIdentity>> login(String identifier, String password);
  Future<AuthResult<AuthIdentity?>> restore();
  Future<AuthResult<void>> logout();
}
