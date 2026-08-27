import 'package:core/errors/error.dart';
import 'package:core/errors/result.dart';
import 'package:feature_auth/data/datasources/auth_local_datasource.dart';
import 'package:feature_auth/data/models/auth_identity_model.dart';
import 'package:feature_auth/domain/entities/auth_identity.dart';
import 'package:feature_auth/domain/repository/i_auth_repository.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: IAuthRepository)
class AuthRepositoryImpl implements IAuthRepository {
  const AuthRepositoryImpl(this._datasource);
  final IAuthLocalDatasource _datasource;

  @override
  Future<Result<String>> issueActivationCode(int actorUserId, String email) =>
      _datasource
          .issueActivationCode(actorUserId, email)
          .toResult(fallback: const StorageFailure());
  @override
  Future<Result<AuthIdentity>> activate(
    String email,
    String code,
    String username,
    String password,
  ) => _datasource
      .activate(email, code, username, password)
      .then((model) => model.toEntity())
      .toResult(fallback: const StorageFailure());
  @override
  Future<Result<AuthIdentity>> login(String identifier, String password) =>
      _datasource
          .login(identifier, password)
          .then((model) => model.toEntity())
          .toResult(fallback: const StorageFailure());
  @override
  Future<Result<AuthIdentity>> loginDemoAdmin() => _datasource
      .loginDemoAdmin()
      .then((model) => model.toEntity())
      .toResult(fallback: const StorageFailure());
  @override
  Future<Result<AuthIdentity?>> restore() => _datasource
      .restore()
      .then((model) => model?.toEntity())
      .toResult(fallback: const StorageFailure());
  @override
  Future<Result<void>> logout() =>
      _datasource.logout().toResult(fallback: const StorageFailure());
}
