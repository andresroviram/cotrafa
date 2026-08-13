import 'package:core/errors/result.dart';
import 'package:features/src/auth/domain/entities/auth_identity.dart';
import 'package:features/src/auth/domain/repository/i_auth_repository.dart';
import 'package:injectable/injectable.dart';

abstract class _AuthUseCase {
  const _AuthUseCase(this._repository);
  final IAuthRepository _repository;
}

@injectable
class IssueActivationCode extends _AuthUseCase {
  const IssueActivationCode(super.repository);
  Future<Result<String>> call(int actorId, String email) =>
      _repository.issueActivationCode(actorId, email);
}

@injectable
class ActivateClient extends _AuthUseCase {
  const ActivateClient(super.repository);
  Future<Result<AuthIdentity>> call(
    String email,
    String code,
    String username,
    String password,
  ) => _repository.activate(email, code, username, password);
}

@injectable
class Login extends _AuthUseCase {
  const Login(super.repository);
  Future<Result<AuthIdentity>> call(String identifier, String password) =>
      _repository.login(identifier, password);
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
