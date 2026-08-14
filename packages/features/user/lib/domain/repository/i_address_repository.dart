import 'package:core/errors/result.dart';
import 'package:feature_user/domain/entities/user_address.dart';

abstract interface class IAddressRepository {
  Future<Result<List<UserAddress>>> list(int actorUserId, int userId);
  Future<Result<UserAddress>> create(
    int actorUserId,
    int userId,
    AddressDraft draft,
  );
  Future<Result<UserAddress>> update(
    int actorUserId,
    int userId,
    int addressId,
    AddressDraft draft,
  );
  Future<Result<UserAddress>> selectPrimary(
    int actorUserId,
    int userId,
    int addressId,
  );
  Future<Result<void>> delete(int actorUserId, int userId, int addressId);
}
