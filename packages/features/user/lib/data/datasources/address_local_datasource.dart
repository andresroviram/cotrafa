import 'package:cootrafa_database/cootrafa_database.dart';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

enum AddressError { unauthorized, inactiveTarget, notFound, storageFailure }

final class AddressResult<T> {
  const AddressResult.ok(this.value) : error = null;
  const AddressResult.failure(this.error) : value = null;
  final T? value;
  final AddressError? error;
}

final class AddressInput {
  const AddressInput(
    this.line1,
    this.line2,
    this.city,
    this.state,
    this.postalCode,
    this.country,
    this.label,
  );
  final String line1, city, country, label;
  final String? line2, state, postalCode;
}

@lazySingleton
final class AddressLocalDatasource {
  AddressLocalDatasource(this._database);
  final CootrafaDatabase _database;
  Future<AddressResult<List<AddressesData>>> list(int actorId, int userId) =>
      _guard(() async {
        final denied = await _authorize(actorId, userId);
        if (denied != null) return AddressResult.failure(denied);
        final rows = await _select(
          'SELECT * FROM addresses WHERE user_id=? ORDER BY id',
          userId,
        ).get();
        return AddressResult.ok(rows.map(_record).toList());
      });
  Future<AddressResult<AddressesData>> create(
    int actorId,
    int userId,
    AddressInput input,
  ) => _transaction(actorId, userId, () async {
    final count = await _select(
      'SELECT COUNT(*) AS count FROM addresses WHERE user_id=?',
      userId,
    ).map((row) => row.read<int>('count')).getSingle();
    final id = await _database
        .customSelect('SELECT COALESCE(MAX(id),0)+1 AS id FROM addresses')
        .map((row) => row.read<int>('id'))
        .getSingle();
    await _database.customStatement(
      'INSERT INTO addresses '
      '(id,user_id,line1,line2,city,state,postal_code,country,label,is_primary) '
      'VALUES (?,?,?,?,?,?,?,?,?,?)',
      <Object?>[
        id,
        userId,
        input.line1,
        input.line2,
        input.city,
        input.state,
        input.postalCode,
        input.country,
        input.label,
        count == 0 ? 1 : 0,
      ],
    );
    return AddressResult.ok((await _address(id, userId))!);
  });
  Future<AddressResult<AddressesData>> update(
    int actorId,
    int userId,
    int addressId,
    AddressInput input,
  ) => _transaction(actorId, userId, () async {
    if (await _address(addressId, userId) == null) return _notFound();
    await _database.customStatement(
      'UPDATE addresses SET line1=?,line2=?,city=?,state=?,postal_code=?,country=?,label=? '
      'WHERE id=? AND user_id=?',
      <Object?>[
        input.line1,
        input.line2,
        input.city,
        input.state,
        input.postalCode,
        input.country,
        input.label,
        addressId,
        userId,
      ],
    );
    return AddressResult.ok((await _address(addressId, userId))!);
  });
  Future<AddressResult<AddressesData>> selectPrimary(
    int actorId,
    int userId,
    int addressId,
  ) => _transaction(actorId, userId, () async {
    if (await _address(addressId, userId) == null) return _notFound();
    await _database.customStatement(
      'UPDATE addresses SET is_primary=0 WHERE user_id=?',
      <Object?>[userId],
    );
    await _database.customStatement(
      'UPDATE addresses SET is_primary=1 WHERE id=? AND user_id=?',
      <Object?>[addressId, userId],
    );
    return AddressResult.ok((await _address(addressId, userId))!);
  });
  Future<AddressResult<bool>> delete(
    int actorId,
    int userId,
    int addressId,
  ) => _transaction(actorId, userId, () async {
    final target = await _address(addressId, userId);
    if (target == null) return _notFound();
    final next = target.isPrimary
        ? await _select(
            'SELECT id FROM addresses WHERE user_id=? AND id<>? ORDER BY id LIMIT 1',
            userId,
            addressId,
          ).getSingleOrNull()
        : null;
    await _database.customStatement(
      'DELETE FROM addresses WHERE id=? AND user_id=?',
      <Object?>[addressId, userId],
    );
    if (next != null) {
      await _database.customStatement(
        'UPDATE addresses SET is_primary=1 WHERE id=?',
        <Object?>[next.read<int>('id')],
      );
    }
    return const AddressResult.ok(true);
  });
  Future<AddressResult<T>> _transaction<T>(
    int actorId,
    int userId,
    Future<AddressResult<T>> Function() action,
  ) => _guard(
    () => _database.transaction(() async {
      final denied = await _authorize(actorId, userId);
      return denied == null ? action() : AddressResult.failure(denied);
    }),
  );
  Future<AddressError?> _authorize(int actorId, int userId) async {
    final actor = await _user(actorId);
    if (actor == null || actor.read<String>('status') != 'active') {
      return AddressError.unauthorized;
    }
    final target = await _user(userId);
    if (target == null || target.read<String>('status') != 'active') {
      return AddressError.inactiveTarget;
    }
    return actor.read<String>('role') == 'admin' || actorId == userId
        ? null
        : AddressError.unauthorized;
  }

  Selectable<QueryRow> _select(String sql, int first, [int? second]) =>
      _database.customSelect(
        sql,
        variables: <Variable<Object>>[
          Variable<int>(first),
          if (second != null) Variable<int>(second),
        ],
      );
  Future<QueryRow?> _user(int id) =>
      _select('SELECT role,status FROM users WHERE id=?', id).getSingleOrNull();
  Future<AddressesData?> _address(int id, int userId) => _select(
    'SELECT * FROM addresses WHERE id=? AND user_id=?',
    id,
    userId,
  ).map(_record).getSingleOrNull();
  AddressesData _record(QueryRow row) => _database.addresses.map(row.data);
  AddressResult<T> _notFound<T>() =>
      const AddressResult.failure(AddressError.notFound);
  Future<AddressResult<T>> _guard<T>(
    Future<AddressResult<T>> Function() action,
  ) async {
    try {
      return await action();
    } on Object {
      return const AddressResult.failure(AddressError.storageFailure);
    }
  }
}
