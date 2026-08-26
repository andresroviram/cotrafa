import 'package:core/errors/result.dart';
import 'package:core/errors/error.dart';
import 'package:feature_auth/domain/entities/auth_identity.dart';
import 'package:feature_auth/domain/repository/i_auth_repository.dart';
import 'package:injectable/injectable.dart';

abstract class _AuthUseCase {
  const _AuthUseCase(this._repository);
  final IAuthRepository _repository;
}

@injectable
class IssueActivationCode extends _AuthUseCase {
  const IssueActivationCode(super.repository);

  Future<Result<String>> call(int actorId, String email) {
    final normalizedEmail = _requiredIdentifier(email, 'Email is required.');
    return switch (normalizedEmail) {
      Error<String>() => Future.value(normalizedEmail),
      Success(value: final value) => _repository.issueActivationCode(
        actorId,
        value,
      ),
    };
  }
}

@injectable
class ActivateClient extends _AuthUseCase {
  const ActivateClient(super.repository);
  Future<Result<AuthIdentity>> call(
    String email,
    String code,
    String username,
    String password,
  ) {
    final normalizedEmail = _requiredIdentifier(email, 'Email is required.');
    if (normalizedEmail case Error<String>(error: final error)) {
      return Future.value(Error<AuthIdentity>(error));
    }
    final normalizedCode = code.trim();
    if (normalizedCode.isEmpty) {
      return Future.value(_validation('Activation code is required.'));
    }
    final normalizedUsername = _requiredIdentifier(
      username,
      'Username is required.',
    );
    if (normalizedUsername case Error<String>(error: final error)) {
      return Future.value(Error<AuthIdentity>(error));
    }
    if (password.isEmpty) {
      return Future.value(_validation('Password is required.'));
    }
    return _repository.activate(
      normalizedEmail.valueOrNull!,
      normalizedCode,
      normalizedUsername.valueOrNull!,
      password,
    );
  }
}

@injectable
class Login extends _AuthUseCase {
  const Login(super.repository);
  Future<Result<AuthIdentity>> call(String identifier, String password) {
    final normalizedIdentifier = _requiredIdentifier(
      identifier,
      'Email or username is required.',
    );
    if (normalizedIdentifier case Error<String>(error: final error)) {
      return Future.value(Error<AuthIdentity>(error));
    }
    if (password.isEmpty) {
      return Future.value(_validation('Password is required.'));
    }
    return _repository.login(normalizedIdentifier.valueOrNull!, password);
  }
}

@injectable
class LoginDemoAdmin extends _AuthUseCase {
  const LoginDemoAdmin(super.repository);

  Future<Result<AuthIdentity>> call() => _repository.loginDemoAdmin();
}

@injectable
class RestoreSession extends _AuthUseCase {
  const RestoreSession(super.repository);
  Future<Result<AuthIdentity?>> call() => _repository.restore();
}

@injectable
class Logout extends _AuthUseCase {
  const Logout(super.repository);
  Future<Result<void>> call() => _repository.logout();
}

Result<String> _requiredIdentifier(String value, String message) {
  final normalized = value.trim().toLowerCase();
  return normalized.isEmpty
      ? Error<String>(ValidationFailure(message: message))
      : Success<String>(normalized);
}

Error<T> _validation<T>(String message) =>
    Error<T>(ValidationFailure(message: message));
