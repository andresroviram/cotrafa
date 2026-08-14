import 'package:core/errors/result.dart';
import 'package:feature_user/domain/entities/delete_outcome.dart';
import 'package:feature_user/domain/entities/user_profile.dart';
import 'package:feature_user/domain/repository/i_user_repository.dart';
import 'package:injectable/injectable.dart';

abstract class _UserUseCase {
  const _UserUseCase(this._repository);

  final IUserRepository _repository;
}

@injectable
final class ListUsers extends _UserUseCase {
  const ListUsers(super.repository);

  Future<Result<List<UserProfile>>> call(int actorUserId) =>
      _repository.listUsers(actorUserId);
}

@injectable
final class GetUser extends _UserUseCase {
  const GetUser(super.repository);

  Future<Result<UserProfile>> call(int actorUserId, int userId) =>
      _repository.getUser(actorUserId, userId);
}

@injectable
final class CreateClient extends _UserUseCase {
  const CreateClient(super.repository);

  Future<Result<UserProfile>> call(
    int actorUserId, {
    required String email,
    required int initialBalanceCop,
  }) => _repository.createClient(
    actorUserId,
    email: email,
    initialBalanceCop: initialBalanceCop,
  );
}

@injectable
final class EditUserProfile extends _UserUseCase {
  const EditUserProfile(super.repository);

  Future<Result<UserProfile>> call(
    int actorUserId,
    int userId, {
    required String? firstName,
    required String? lastName,
    required DateTime? birthDate,
    required String? phone,
  }) => _repository.editProfile(
    actorUserId,
    userId,
    firstName: firstName,
    lastName: lastName,
    birthDate: birthDate,
    phone: phone,
  );
}

@injectable
final class DeleteUser extends _UserUseCase {
  const DeleteUser(super.repository);

  Future<Result<DeleteOutcome>> call(int actorUserId, int userId) =>
      _repository.deleteUser(actorUserId, userId);
}
