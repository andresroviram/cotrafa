import 'package:core/errors/result.dart';
import 'package:feature_auth/data/datasources/auth_local_datasource.dart';
import 'package:feature_auth/domain/entities/auth_identity.dart';
import 'package:feature_auth/domain/repository/i_auth_repository.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: IAuthRepository)
class AuthRepositoryImpl implements IAuthRepository {
  const AuthRepositoryImpl(this._datasource);
  final IAuthLocalDatasource _datasource;

  @override
  Future<Result<String>> issueActivationCode(int actorUserId, String email) =>
      _datasource.issueActivationCode(actorUserId, email).toDomainResult();
  @override
  Future<Result<AuthIdentity>> activate(
    String email,
    String code,
    String username,
    String password,
  ) => _datasource.activate(email, code, username, password).toDomainResult();
  @override
  Future<Result<AuthIdentity>> login(String identifier, String password) =>
      _datasource.login(identifier, password).toDomainResult();
  @override
  Future<Result<AuthIdentity>> loginDemoAdmin() =>
      _datasource.loginDemoAdmin().toDomainResult();
  @override
  Future<Result<AuthIdentity?>> restore() =>
      _datasource.restore().toDomainResult();
  @override
  Future<Result<void>> logout() => _datasource.logout().toDomainResult();
}
