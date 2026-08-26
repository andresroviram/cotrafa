import 'package:core/errors/error.dart';
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
  ) {
    final normalized = _validateAddress(draft);
    return switch (normalized) {
      Error<AddressDraft>(error: final error) => Future.value(
        Error<UserAddress>(error),
      ),
      Success(value: final value) => repository.create(
        actorUserId,
        userId,
        value,
      ),
    };
  }
}

@injectable
final class UpdateAddress extends _AddressUseCase {
  const UpdateAddress(super.repository);

  Future<Result<UserAddress>> call(
    int actorUserId,
    int userId,
    int addressId,
    AddressDraft draft,
  ) {
    final normalized = _validateAddress(draft);
    return switch (normalized) {
      Error<AddressDraft>(error: final error) => Future.value(
        Error<UserAddress>(error),
      ),
      Success(value: final value) => repository.update(
        actorUserId,
        userId,
        addressId,
        value,
      ),
    };
  }
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

Result<AddressDraft> _validateAddress(AddressDraft draft) {
  final line1 = _required(draft.line1, 'Address is required.');
  if (line1 case Error<String>(error: final error)) {
    return Error<AddressDraft>(error);
  }
  final city = _required(draft.city, 'City is required.');
  if (city case Error<String>(error: final error)) {
    return Error<AddressDraft>(error);
  }
  final country = _required(draft.country, 'Country is required.');
  if (country case Error<String>(error: final error)) {
    return Error<AddressDraft>(error);
  }
  final label = _required(draft.label, 'Label is required.');
  if (label case Error<String>(error: final error)) {
    return Error<AddressDraft>(error);
  }
  return Success<AddressDraft>(
    AddressDraft(
      line1: line1.valueOrNull!,
      line2: _optional(draft.line2),
      city: city.valueOrNull!,
      state: _optional(draft.state),
      postalCode: _optional(draft.postalCode),
      country: country.valueOrNull!,
      label: label.valueOrNull!,
    ),
  );
}

Result<String> _required(String value, String message) {
  final normalized = value.trim();
  return normalized.isEmpty
      ? Error<String>(ValidationFailure(message: message))
      : Success<String>(normalized);
}

String? _optional(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}
