import 'package:core/errors/result.dart';
import 'package:feature_user/domain/entities/delete_outcome.dart';
import 'package:feature_user/domain/entities/user_profile.dart';

abstract interface class IUserRepository {
  Future<Result<List<UserProfile>>> listUsers(int actorUserId);
  Future<Result<UserProfile>> getUser(int actorUserId, int userId);
  Future<Result<UserProfile>> createClient(
    int actorUserId, {
    required String email,
    required int initialBalanceCop,
  });
  Future<Result<UserProfile>> editProfile(
    int actorUserId,
    int userId, {
    required String? firstName,
    required String? lastName,
    required DateTime? birthDate,
    required String? phone,
  });
  Future<Result<DeleteOutcome>> deleteUser(int actorUserId, int userId);
}
