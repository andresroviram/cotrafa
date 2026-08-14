import 'package:core/errors/result.dart';
import 'package:feature_user/domain/entities/user_address.dart';
import 'package:feature_user/domain/repository/i_address_repository.dart';
import 'package:injectable/injectable.dart';

abstract class _AddressUseCase {
  const _AddressUseCase(this.repository);

  final IAddressRepository repository;
}

@injectable
final class ListAddresses extends _AddressUseCase {
  const ListAddresses(super.repository);

  Future<Result<List<UserAddress>>> call(int actorUserId, int userId) =>
      repository.list(actorUserId, userId);
}

@injectable
final class CreateAddress extends _AddressUseCase {
  const CreateAddress(super.repository);

  Future<Result<UserAddress>> call(
    int actorUserId,
    int userId,
    AddressDraft draft,
  ) => repository.create(actorUserId, userId, draft);
}

@injectable
final class UpdateAddress extends _AddressUseCase {
  const UpdateAddress(super.repository);

  Future<Result<UserAddress>> call(
    int actorUserId,
    int userId,
    int addressId,
    AddressDraft draft,
  ) => repository.update(actorUserId, userId, addressId, draft);
}

@injectable
final class SelectPrimaryAddress extends _AddressUseCase {
  const SelectPrimaryAddress(super.repository);

  Future<Result<UserAddress>> call(
    int actorUserId,
    int userId,
    int addressId,
  ) => repository.selectPrimary(actorUserId, userId, addressId);
}

@injectable
final class DeleteAddress extends _AddressUseCase {
  const DeleteAddress(super.repository);

  Future<Result<void>> call(int actorUserId, int userId, int addressId) =>
      repository.delete(actorUserId, userId, addressId);
}
