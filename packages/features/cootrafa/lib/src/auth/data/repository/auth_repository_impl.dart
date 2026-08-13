import 'package:core/errors/error.dart';
import 'package:core/errors/result.dart';
import 'package:features/src/auth/data/datasources/auth_local_datasource.dart';
import 'package:features/src/auth/domain/entities/auth_identity.dart';
import 'package:features/src/auth/domain/repository/i_auth_repository.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: IAuthRepository)
class AuthRepositoryImpl implements IAuthRepository {
  const AuthRepositoryImpl(this._datasource);
  final IAuthLocalDatasource _datasource;

  Future<Result<T>> _map<T>(Future<AuthResult<T>> pending) async {
    final result = await pending;
    if (result.error == null) return Success<T>(result.value as T);
    return Error<T>(switch (result.error!) {
      AuthError.unauthorized => const UnauthorizedFailure(),
      AuthError.clientNotPending => const ValidationFailure(
        message: 'Client is not pending activation.',
      ),
      AuthError.identifierTaken => const DuplicateFailure(),
      AuthError.invalidCredentials => const AuthFailure(),
      AuthError.storageFailure => const StorageFailure(),
    });
  }

  @override
  Future<Result<String>> issueActivationCode(int actorUserId, String email) =>
      _map(_datasource.issueActivationCode(actorUserId, email));
  @override
  Future<Result<AuthIdentity>> activate(
    String email,
    String code,
    String username,
    String password,
  ) => _map(_datasource.activate(email, code, username, password));
  @override
  Future<Result<AuthIdentity>> login(String identifier, String password) =>
      _map(_datasource.login(identifier, password));
  @override
  Future<Result<AuthIdentity?>> restore() => _map(_datasource.restore());
  @override
  Future<Result<void>> logout() => _map(_datasource.logout());
}
