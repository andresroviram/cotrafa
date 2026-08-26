import 'package:core/errors/error.dart';
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
    required String firstName,
    required String lastName,
    required DateTime? birthDate,
    required String? phone,
    required int initialBalanceCop,
  }) {
    final normalized = _validateProfileInput(
      firstName: firstName,
      lastName: lastName,
      phone: phone,
    );
    if (normalized case Error<_ProfileInput>(error: final error)) {
      return Future.value(Error<UserProfile>(error));
    }
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      return Future.value(
        const Error<UserProfile>(
          ValidationFailure(message: 'Email is required.'),
        ),
      );
    }
    if (initialBalanceCop < 0) {
      return Future.value(
        const Error<UserProfile>(
          ValidationFailure(message: 'Initial balance cannot be negative.'),
        ),
      );
    }
    final values = normalized.valueOrNull!;
    return _repository.createClient(
      actorUserId,
      email: normalizedEmail,
      firstName: values.firstName,
      lastName: values.lastName,
      birthDate: birthDate,
      phone: values.phone,
      initialBalanceCop: initialBalanceCop,
    );
  }
}

@injectable
final class EditUserProfile extends _UserUseCase {
  const EditUserProfile(super.repository);

  Future<Result<UserProfile>> call(
    int actorUserId,
    int userId, {
    required String firstName,
    required String lastName,
    required DateTime? birthDate,
    required String? phone,
  }) {
    final normalized = _validateProfileInput(
      firstName: firstName,
      lastName: lastName,
      phone: phone,
    );
    if (normalized case Error<_ProfileInput>(error: final error)) {
      return Future.value(Error<UserProfile>(error));
    }
    final values = normalized.valueOrNull!;
    return _repository.editProfile(
      actorUserId,
      userId,
      firstName: values.firstName,
      lastName: values.lastName,
      birthDate: birthDate,
      phone: values.phone,
    );
  }
}

@injectable
final class DeleteUser extends _UserUseCase {
  const DeleteUser(super.repository);

  Future<Result<DeleteOutcome>> call(int actorUserId, int userId) =>
      _repository.deleteUser(actorUserId, userId);
}

typedef _ProfileInput = ({String firstName, String lastName, String? phone});

Result<_ProfileInput> _validateProfileInput({
  required String firstName,
  required String lastName,
  required String? phone,
}) {
  final normalizedFirstName = firstName.trim();
  final normalizedLastName = lastName.trim();
  if (normalizedFirstName.isEmpty || normalizedLastName.isEmpty) {
    return const Error<_ProfileInput>(
      ValidationFailure(message: 'First name and last name are required.'),
    );
  }
  final normalizedPhone = phone?.trim();
  return Success<_ProfileInput>((
    firstName: normalizedFirstName,
    lastName: normalizedLastName,
    phone: normalizedPhone == null || normalizedPhone.isEmpty
        ? null
        : normalizedPhone,
  ));
}
