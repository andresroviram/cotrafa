import 'package:core/errors/error.dart';
import 'package:core/errors/result.dart';
import 'package:feature_user/data/datasources/address_local_datasource.dart';
import 'package:feature_user/domain/entities/user_address.dart';
import 'package:feature_user/domain/repository/i_address_repository.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: IAddressRepository)
final class AddressRepositoryImpl implements IAddressRepository {
  const AddressRepositoryImpl(this._datasource);

  final IAddressLocalDatasource _datasource;

  @override
  Future<Result<List<UserAddress>>> list(int actorUserId, int userId) =>
      _datasource
          .list(actorUserId, userId)
          .toResult(fallback: const StorageFailure());

  @override
  Future<Result<UserAddress>> create(
    int actorUserId,
    int userId,
    AddressDraft draft,
  ) => _datasource
      .create(actorUserId, userId, draft)
      .toResult(fallback: const StorageFailure());

  @override
  Future<Result<UserAddress>> update(
    int actorUserId,
    int userId,
    int addressId,
    AddressDraft draft,
  ) => _datasource
      .update(actorUserId, userId, addressId, draft)
      .toResult(fallback: const StorageFailure());

  @override
  Future<Result<UserAddress>> selectPrimary(
    int actorUserId,
    int userId,
    int addressId,
  ) => _datasource
      .selectPrimary(actorUserId, userId, addressId)
      .toResult(fallback: const StorageFailure());

  @override
  Future<Result<void>> delete(int actorUserId, int userId, int addressId) =>
      _datasource
          .delete(actorUserId, userId, addressId)
          .toResult(fallback: const StorageFailure());
}
