import 'package:cotrafa_database/cotrafa_database.dart';
import 'package:core/errors/error.dart';
import 'package:drift/drift.dart';
import 'package:feature_user/domain/entities/delete_outcome.dart';
import 'package:feature_user/domain/entities/user_profile.dart';
import 'package:injectable/injectable.dart';

abstract interface class IUserLocalDatasource {
  Future<List<UserProfile>> listUsers(int actorUserId);
  Future<UserProfile> getUser(int actorUserId, int userId);
  Future<UserProfile> createClient(
    int actorUserId, {
    required String email,
    required String firstName,
    required String lastName,
    required DateTime? birthDate,
    required String? phone,
    required int initialBalanceCop,
  });
  Future<UserProfile> editProfile(
    int actorUserId,
    int userId, {
    required String firstName,
    required String lastName,
    required DateTime? birthDate,
    required String? phone,
  });
  Future<DeleteOutcome> deleteUser(int actorUserId, int userId);
}

@LazySingleton(as: IUserLocalDatasource)
final class UserLocalDatasource implements IUserLocalDatasource {
  UserLocalDatasource(this._database, CotrafaDatabaseSeed seed)
    : protectedAdminUserId = seed.userId;
  final CotrafaDatabase _database;
  final int protectedAdminUserId;

  @override
  Future<List<UserProfile>> listUsers(int actorUserId) async {
    if (!await _isActiveAdmin(actorUserId)) {
      throw const UnauthorizedException();
    }
    final rows = await (_database.select(
      _database.users,
    )..orderBy([(table) => OrderingTerm.asc(table.id)])).get();
    return rows.map(_profile).toList();
  }

  @override
  Future<UserProfile> getUser(int actorUserId, int userId) async {
    final actor = await _user(actorUserId);
    if (!_canAccess(actor, userId)) {
      throw const UnauthorizedException();
    }
    final target = await _user(userId);
    if (target == null) throw const NotFoundException();
    return _profile(target);
  }

  @override
  Future<UserProfile> createClient(
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
    if (initialBalanceCop < 0) {
      throw const ValidationException(
        message: 'Initial balance cannot be negative.',
      );
    }
    final normalizedFirstName = _requiredName(firstName);
    final normalizedLastName = _requiredName(lastName);
    final normalizedPhone = _optional(phone);
    final normalized = _normalize(email);
    if (await _identifierExists(normalized)) {
      throw const DuplicateException();
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = await _database
        .into(_database.users)
        .insert(
          UsersCompanion.insert(
            email: normalized,
            fullName: '$normalizedFirstName $normalizedLastName',
            firstName: Value(normalizedFirstName),
            lastName: Value(normalizedLastName),
            birthDate: Value(_date(birthDate)),
            phone: Value(normalizedPhone),
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
            normalized: normalized,
            userId: id,
            kind: 'email',
          ),
        );
    return _profile((await _user(id))!);
  });

  @override
  Future<UserProfile> editProfile(
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
    final normalizedFirstName = _requiredName(firstName);
    final normalizedLastName = _requiredName(lastName);
    final normalizedPhone = _optional(phone);
    await (_database.update(
      _database.users,
    )..where((table) => table.id.equals(userId))).write(
      UsersCompanion(
        fullName: Value('$normalizedFirstName $normalizedLastName'),
        firstName: Value(normalizedFirstName),
        lastName: Value(normalizedLastName),
        birthDate: Value(_date(birthDate)),
        phone: Value(normalizedPhone),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
    return _profile((await _user(userId))!);
  });

  @override
  Future<DeleteOutcome> deleteUser(int actorUserId, int userId) =>
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
          return DeleteOutcome.deactivated;
        }
        await (_database.delete(
          _database.users,
        )..where((table) => table.id.equals(userId))).go();
        return DeleteOutcome.deleted;
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

  UserProfile _profile(User user) => UserProfile(
    id: user.id,
    email: user.email,
    fullName: user.fullName,
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

  String _normalize(String value) => value.trim().toLowerCase();

  String? _optional(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  String _requiredName(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      throw const ValidationException(
        message: 'First name and last name are required.',
      );
    }
    return normalized;
  }

  int? _date(DateTime? value) => value == null
      ? null
      : DateTime.utc(value.year, value.month, value.day).millisecondsSinceEpoch;
}
