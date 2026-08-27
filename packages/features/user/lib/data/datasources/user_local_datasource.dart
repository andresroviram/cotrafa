import 'package:cotrafa_database/cotrafa_database.dart';
import 'package:core/errors/error.dart';
import 'package:drift/drift.dart';
import 'package:feature_user/data/models/delete_outcome_model.dart';
import 'package:feature_user/data/models/user_profile_model.dart';
import 'package:injectable/injectable.dart';

abstract interface class IUserLocalDatasource {
  Future<List<UserProfileModel>> listUsers(int actorUserId);
  Future<UserProfileModel> getUser(int actorUserId, int userId);
  Future<UserProfileModel> createClient(
    int actorUserId, {
    required String email,
    required String firstName,
    required String lastName,
    required DateTime? birthDate,
    required String? phone,
    required int initialBalanceCop,
  });
  Future<UserProfileModel> editProfile(
    int actorUserId,
    int userId, {
    required String firstName,
    required String lastName,
    required DateTime? birthDate,
    required String? phone,
  });
  Future<DeleteOutcomeModel> deleteUser(int actorUserId, int userId);
}

@LazySingleton(as: IUserLocalDatasource)
final class UserLocalDatasource implements IUserLocalDatasource {
  UserLocalDatasource(this._database, CotrafaDatabaseSeed seed)
    : protectedAdminUserId = seed.userId;
  final CotrafaDatabase _database;
  final int protectedAdminUserId;

  @override
  Future<List<UserProfileModel>> listUsers(int actorUserId) async {
    if (!await _isActiveAdmin(actorUserId)) {
      throw const UnauthorizedException();
    }
    final rows = await _profileRows();
    return rows.map(_profile).toList();
  }

  @override
  Future<UserProfileModel> getUser(int actorUserId, int userId) async {
    final actor = await _user(actorUserId);
    if (!_canAccess(actor, userId)) {
      throw const UnauthorizedException();
    }
    final target = await _profileById(userId);
    if (target == null) throw const NotFoundException();
    return target;
  }

  @override
  Future<UserProfileModel> createClient(
    int actorUserId, {
    required String email,
    required String firstName,
    required String lastName,
    required DateTime? birthDate,
    required String? phone,
    required int initialBalanceCop,
  }) => _database.transaction(() async {
    if (!await _isActiveAdmin(actorUserId)) {
      throw const UnauthorizedException();
    }
    if (await _identifierExists(email)) {
      throw const DuplicateException();
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = await _database
        .into(_database.users)
        .insert(
          UsersCompanion.insert(
            email: email,
            fullName: '$firstName $lastName',
            firstName: Value(firstName),
            lastName: Value(lastName),
            birthDate: Value(_date(birthDate)),
            phone: Value(phone),
            role: 'client',
            status: 'pendingActivation',
            balanceCop: Value(initialBalanceCop),
            createdAt: now,
            updatedAt: now,
          ),
        );
    await _database
        .into(_database.loginIdentifiers)
        .insert(
          LoginIdentifiersCompanion.insert(
            normalized: email,
            userId: id,
            kind: 'email',
          ),
        );
    return (await _profileById(id))!;
  });

  @override
  Future<UserProfileModel> editProfile(
    int actorUserId,
    int userId, {
    required String firstName,
    required String lastName,
    required DateTime? birthDate,
    required String? phone,
  }) => _database.transaction(() async {
    final actor = await _user(actorUserId);
    if (!_canAccess(actor, userId)) {
      throw const UnauthorizedException();
    }
    final target = await _user(userId);
    if (target == null) {
      throw const NotFoundException();
    }
    await (_database.update(
      _database.users,
    )..where((table) => table.id.equals(userId))).write(
      UsersCompanion(
        fullName: Value('$firstName $lastName'),
        firstName: Value(firstName),
        lastName: Value(lastName),
        birthDate: Value(_date(birthDate)),
        phone: Value(phone),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
    return (await _profileById(userId))!;
  });

  @override
  Future<DeleteOutcomeModel> deleteUser(int actorUserId, int userId) =>
      _database.transaction(() async {
        if (!await _isActiveAdmin(actorUserId)) {
          throw const UnauthorizedException();
        }
        if (userId == protectedAdminUserId) {
          throw const ValidationException(
            message: 'Demo admin cannot be deleted.',
          );
        }
        if (await _user(userId) == null) {
          throw const NotFoundException();
        }
        final transferCount = _database.transfers.id.count();
        final countRow =
            await (_database.selectOnly(_database.transfers)
                  ..addColumns(<Expression<Object>>[transferCount])
                  ..where(
                    _database.transfers.originUserId.equals(userId) |
                        _database.transfers.destinationUserId.equals(userId),
                  ))
                .getSingle();
        final references = countRow.read(transferCount) ?? 0;
        await (_database.delete(
          _database.localSession,
        )..where((table) => table.userId.equals(userId))).go();
        if (references > 0) {
          await (_database.update(
            _database.users,
          )..where((table) => table.id.equals(userId))).write(
            UsersCompanion(
              status: const Value('inactive'),
              passwordHash: const Value(null),
              activationCodeHash: const Value(null),
              updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
            ),
          );
          return DeleteOutcomeModel.deactivated;
        }
        await (_database.delete(
          _database.users,
        )..where((table) => table.id.equals(userId))).go();
        return DeleteOutcomeModel.deleted;
      });

  Future<User?> _user(int id) => (_database.select(
    _database.users,
  )..where((table) => table.id.equals(id))).getSingleOrNull();

  Future<bool> _isActiveAdmin(int id) async {
    final actor = await _user(id);
    return actor != null && actor.role == 'admin' && actor.status == 'active';
  }

  bool _canAccess(User? actor, int targetId) =>
      actor != null &&
      actor.status == 'active' &&
      (actor.role == 'admin' || actor.id == targetId);

  Future<bool> _identifierExists(String normalized) =>
      (_database.select(_database.loginIdentifiers)
            ..where((table) => table.normalized.equals(normalized)))
          .getSingleOrNull()
          .then((identifier) => identifier != null);

  Future<List<TypedResult>> _profileRows({int? userId}) {
    final query = _database.select(_database.users).join([
      leftOuterJoin(
        _database.loginIdentifiers,
        _database.loginIdentifiers.userId.equalsExp(_database.users.id) &
            _database.loginIdentifiers.kind.equals('username'),
      ),
    ]);
    if (userId == null) {
      query.orderBy(<OrderingTerm>[OrderingTerm.asc(_database.users.id)]);
    } else {
      query.where(_database.users.id.equals(userId));
    }
    return query.get();
  }

  Future<UserProfileModel?> _profileById(int userId) async {
    final rows = await _profileRows(userId: userId);
    return rows.isEmpty ? null : _profile(rows.single);
  }

  UserProfileModel _profile(TypedResult row) {
    final user = row.readTable(_database.users);
    final username = row
        .readTableOrNull(_database.loginIdentifiers)
        ?.normalized;
    return UserProfileModel(
      id: user.id,
      email: user.email,
      fullName: user.fullName,
      username: username,
      firstName: user.firstName,
      lastName: user.lastName,
      birthDate: switch (user.birthDate) {
        final milliseconds? => DateTime.fromMillisecondsSinceEpoch(
          milliseconds,
          isUtc: true,
        ),
        null => null,
      },
      phone: user.phone,
      role: user.role,
      status: user.status,
      balanceCop: user.balanceCop,
    );
  }

  int? _date(DateTime? value) => value == null
      ? null
      : DateTime.utc(value.year, value.month, value.day).millisecondsSinceEpoch;
}
