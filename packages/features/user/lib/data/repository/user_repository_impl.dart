import 'package:core/errors/error.dart';
import 'package:core/errors/result.dart';
import 'package:feature_user/data/datasources/user_local_datasource.dart';
import 'package:feature_user/data/models/delete_outcome_model.dart';
import 'package:feature_user/data/models/user_profile_model.dart';
import 'package:feature_user/domain/entities/delete_outcome.dart';
import 'package:feature_user/domain/entities/user_profile.dart';
import 'package:feature_user/domain/repository/i_user_repository.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: IUserRepository)
final class UserRepositoryImpl implements IUserRepository {
  const UserRepositoryImpl(this._datasource);

  final IUserLocalDatasource _datasource;

  @override
  Future<Result<List<UserProfile>>> listUsers(int actorUserId) => _datasource
      .listUsers(actorUserId)
      .then((models) => models.map((model) => model.toEntity()).toList())
      .toResult(fallback: const StorageFailure());

  @override
  Future<Result<UserProfile>> getUser(int actorUserId, int userId) =>
      _datasource
          .getUser(actorUserId, userId)
          .then((model) => model.toEntity())
          .toResult(fallback: const StorageFailure());

  @override
  Future<Result<UserProfile>> createClient(
    int actorUserId, {
    required String email,
    required String firstName,
    required String lastName,
    required DateTime? birthDate,
    required String? phone,
    required int initialBalanceCop,
  }) => _datasource
      .createClient(
        actorUserId,
        email: email,
        firstName: firstName,
        lastName: lastName,
        birthDate: birthDate,
        phone: phone,
        initialBalanceCop: initialBalanceCop,
      )
      .then((model) => model.toEntity())
      .toResult(fallback: const StorageFailure());

  @override
  Future<Result<UserProfile>> editProfile(
    int actorUserId,
    int userId, {
    required String firstName,
    required String lastName,
    required DateTime? birthDate,
    required String? phone,
  }) => _datasource
      .editProfile(
        actorUserId,
        userId,
        firstName: firstName,
        lastName: lastName,
        birthDate: birthDate,
        phone: phone,
      )
      .then((model) => model.toEntity())
      .toResult(fallback: const StorageFailure());

  @override
  Future<Result<DeleteOutcome>> deleteUser(int actorUserId, int userId) =>
      _datasource
          .deleteUser(actorUserId, userId)
          .then((model) => model.toEntity())
          .toResult(fallback: const StorageFailure());
}
