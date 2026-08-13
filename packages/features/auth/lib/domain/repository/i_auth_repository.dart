import 'package:core/errors/result.dart';
import 'package:feature_auth/domain/entities/auth_identity.dart';

abstract interface class IAuthRepository {
  Future<Result<String>> issueActivationCode(int actorUserId, String email);
  Future<Result<AuthIdentity>> activate(
    String email,
    String code,
    String username,
    String password,
  );
  Future<Result<AuthIdentity>> login(String identifier, String password);
  Future<Result<AuthIdentity>> loginDemoAdmin();
  Future<Result<AuthIdentity?>> restore();
  Future<Result<void>> logout();
}
