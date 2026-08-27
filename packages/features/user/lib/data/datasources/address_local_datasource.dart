import 'package:cotrafa_database/cotrafa_database.dart';
import 'package:core/errors/error.dart';
import 'package:drift/drift.dart';
import 'package:feature_user/data/datasources/mappers/user_database_mapper.dart';
import 'package:feature_user/data/models/user_address_model.dart';
import 'package:feature_user/domain/entities/user_address.dart';
import 'package:injectable/injectable.dart';

abstract interface class IAddressLocalDatasource {
  Future<List<UserAddressModel>> list(int actorUserId, int userId);
  Future<UserAddressModel> create(
    int actorUserId,
    int userId,
    AddressDraft draft,
  );
  Future<UserAddressModel> update(
    int actorUserId,
    int userId,
    int addressId,
    AddressDraft draft,
  );
  Future<UserAddressModel> selectPrimary(
    int actorUserId,
    int userId,
    int addressId,
  );
  Future<void> delete(int actorUserId, int userId, int addressId);
}

@LazySingleton(as: IAddressLocalDatasource)
final class AddressLocalDatasource implements IAddressLocalDatasource {
  AddressLocalDatasource(this._database);

  final CotrafaDatabase _database;

  @override
  Future<List<UserAddressModel>> list(int actorUserId, int userId) async {
    await _authorize(actorUserId, userId);
    final query = _database.select(_database.addresses)
      ..where((table) => table.userId.equals(userId))
      ..orderBy([(table) => OrderingTerm.asc(table.id)]);
    return query.map((row) => row.toUserAddressModel()).get();
  }

  @override
  Future<UserAddressModel> create(
    int actorUserId,
    int userId,
    AddressDraft draft,
  ) => _database.transaction(() async {
    await _authorize(actorUserId, userId);
    final existing =
        await (_database.select(_database.addresses)
              ..where((table) => table.userId.equals(userId))
              ..limit(1))
            .getSingleOrNull();
    final id = await _database
        .into(_database.addresses)
        .insert(
          AddressesCompanion.insert(
            userId: userId,
            line1: draft.line1,
            line2: Value(draft.line2),
            city: draft.city,
            state: Value(draft.state),
            postalCode: Value(draft.postalCode),
            country: Value(draft.country),
            label: draft.label,
            isPrimary: Value(existing == null),
          ),
        );
    return (await _addressQuery(
      id,
      userId,
    ).map((row) => row.toUserAddressModel()).getSingleOrNull())!;
  });

  @override
  Future<UserAddressModel> update(
    int actorUserId,
    int userId,
    int addressId,
    AddressDraft draft,
  ) => _database.transaction(() async {
    await _authorize(actorUserId, userId);
    await _requireAddress(addressId, userId);
    final affected =
        await (_database.update(_database.addresses)..where(
              (table) =>
                  table.id.equals(addressId) & table.userId.equals(userId),
            ))
            .write(
              AddressesCompanion(
                line1: Value(draft.line1),
                line2: Value(draft.line2),
                city: Value(draft.city),
                state: Value(draft.state),
                postalCode: Value(draft.postalCode),
                country: Value(draft.country),
                label: Value(draft.label),
              ),
            );
    if (affected != 1) throw const StorageException();
    return (await _addressQuery(
      addressId,
      userId,
    ).map((row) => row.toUserAddressModel()).getSingleOrNull())!;
  });

  @override
  Future<UserAddressModel> selectPrimary(
    int actorUserId,
    int userId,
    int addressId,
  ) => _database.transaction(() async {
    await _authorize(actorUserId, userId);
    await _requireAddress(addressId, userId);
    await (_database.update(_database.addresses)
          ..where((table) => table.userId.equals(userId)))
        .write(const AddressesCompanion(isPrimary: Value(false)));
    final affected =
        await (_database.update(_database.addresses)..where(
              (table) =>
                  table.id.equals(addressId) & table.userId.equals(userId),
            ))
            .write(const AddressesCompanion(isPrimary: Value(true)));
    if (affected != 1) throw const StorageException();
    return (await _addressQuery(
      addressId,
      userId,
    ).map((row) => row.toUserAddressModel()).getSingleOrNull())!;
  });

  @override
  Future<void> delete(int actorUserId, int userId, int addressId) =>
      _database.transaction(() async {
        await _authorize(actorUserId, userId);
        final target = await _requireAddress(addressId, userId);
        final next = target.isPrimary
            ? await (_database.select(_database.addresses)
                    ..where(
                      (table) =>
                          table.userId.equals(userId) &
                          table.id.equals(addressId).not(),
                    )
                    ..orderBy([(table) => OrderingTerm.asc(table.id)])
                    ..limit(1))
                  .getSingleOrNull()
            : null;
        final affected =
            await (_database.delete(_database.addresses)..where(
                  (table) =>
                      table.id.equals(addressId) & table.userId.equals(userId),
                ))
                .go();
        if (affected != 1) throw const StorageException();
        if (next != null) {
          final promoted =
              await (_database.update(_database.addresses)
                    ..where((table) => table.id.equals(next.id)))
                  .write(const AddressesCompanion(isPrimary: Value(true)));
          if (promoted != 1) throw const StorageException();
        }
      });

  Future<void> _authorize(int actorUserId, int userId) async {
    final actor = await _findUser(actorUserId);
    if (actor == null || actor.status != 'active') {
      throw const UnauthorizedException();
    }
    final target = await _findUser(userId);
    if (target == null) throw const NotFoundException();
    if (target.status != 'active') {
      throw const ValidationException(
        message: 'Inactive users cannot manage addresses.',
      );
    }
    if (actor.role != 'admin' && actor.id != userId) {
      throw const UnauthorizedException();
    }
  }

  Future<User?> _findUser(int id) => (_database.select(
    _database.users,
  )..where((table) => table.id.equals(id))).getSingleOrNull();

  Selectable<AddressesData> _addressQuery(int id, int userId) =>
      _database.select(_database.addresses)
        ..where((table) => table.id.equals(id) & table.userId.equals(userId));

  Future<AddressesData> _requireAddress(int id, int userId) async {
    final address = await _addressQuery(id, userId).getSingleOrNull();
    if (address == null) throw const NotFoundException();
    return address;
  }
}
