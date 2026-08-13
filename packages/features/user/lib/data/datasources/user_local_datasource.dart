import 'package:cootrafa_database/cootrafa_database.dart';
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
    required String fullName,
    required int initialBalanceCop,
  });
  Future<UserProfile> editProfile(
    int actorUserId,
    int userId, {
    required String fullName,
  });
  Future<DeleteOutcome> deleteUser(int actorUserId, int userId);
}

@LazySingleton(as: IUserLocalDatasource)
final class UserLocalDatasource implements IUserLocalDatasource {
  UserLocalDatasource(this._database, CootrafaDatabaseSeed seed)
    : protectedAdminUserId = seed.userId;
  final CootrafaDatabase _database;
  final int protectedAdminUserId;

  @override
  Future<List<UserProfile>> listUsers(int actorUserId) async {
    if (!await _isActiveAdmin(actorUserId)) {
      throw const UnauthorizedException();
    }
    final rows = await _database
        .customSelect(
          'SELECT id,email,full_name,role,status,balance_cop FROM users ORDER BY id',
        )
        .get();
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
    required String fullName,
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
    final normalized = _normalize(email);
    if (await _identifierExists(normalized)) {
      throw const DuplicateException();
    }
    final id = await _database
        .customSelect('SELECT COALESCE(MAX(id),0)+1 AS id FROM users')
        .map((row) => row.read<int>('id'))
        .getSingle();
    final now = DateTime.now().millisecondsSinceEpoch;
    await _database.customStatement(
      "INSERT INTO users (id,email,full_name,role,status,balance_cop,created_at,updated_at) "
      "VALUES (?, ?, ?, 'client', 'pendingActivation', ?, ?, ?)",
      <Object?>[id, normalized, fullName, initialBalanceCop, now, now],
    );
    await _database.customStatement(
      "INSERT INTO login_identifiers VALUES (?,?,'email')",
      <Object?>[normalized, id],
    );
    return _profile((await _user(id))!);
  });

  @override
  Future<UserProfile> editProfile(
    int actorUserId,
    int userId, {
    required String fullName,
  }) => _database.transaction(() async {
    final actor = await _user(actorUserId);
    if (!_canAccess(actor, userId)) {
      throw const UnauthorizedException();
    }
    if (await _user(userId) == null) {
      throw const NotFoundException();
    }
    await _database.customStatement(
      'UPDATE users SET full_name=?,updated_at=? WHERE id=?',
      <Object?>[fullName, DateTime.now().millisecondsSinceEpoch, userId],
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
        final references = await _database
            .customSelect(
              'SELECT COUNT(*) AS count FROM transfers '
              'WHERE origin_user_id=? OR destination_user_id=?',
              variables: <Variable<Object>>[
                Variable<int>(userId),
                Variable<int>(userId),
              ],
            )
            .map((row) => row.read<int>('count'))
            .getSingle();
        await _database.customStatement(
          'DELETE FROM local_session WHERE user_id=?',
          <Object?>[userId],
        );
        if (references > 0) {
          await _database.customStatement(
            "UPDATE users SET status='inactive',password_hash=NULL,"
            'activation_code_hash=NULL,updated_at=? WHERE id=?',
            <Object?>[DateTime.now().millisecondsSinceEpoch, userId],
          );
          return DeleteOutcome.deactivated;
        }
        await _database.customStatement(
          'DELETE FROM users WHERE id=?',
          <Object?>[userId],
        );
        return DeleteOutcome.deleted;
      });

  Future<QueryRow?> _user(int id) => _database
      .customSelect(
        'SELECT id,email,full_name,role,status,balance_cop FROM users WHERE id=?',
        variables: <Variable<Object>>[Variable<int>(id)],
      )
      .getSingleOrNull();

  Future<bool> _isActiveAdmin(int id) async {
    final actor = await _user(id);
    return actor != null &&
        actor.read<String>('role') == 'admin' &&
        actor.read<String>('status') == 'active';
  }

  bool _canAccess(QueryRow? actor, int targetId) =>
      actor != null &&
      actor.read<String>('status') == 'active' &&
      (actor.read<String>('role') == 'admin' ||
          actor.read<int>('id') == targetId);

  Future<bool> _identifierExists(String normalized) => _database
      .customSelect(
        'SELECT 1 FROM login_identifiers WHERE normalized=?',
        variables: <Variable<Object>>[Variable<String>(normalized)],
      )
      .getSingleOrNull()
      .then((row) => row != null);

  UserProfile _profile(QueryRow row) => UserProfile(
    id: row.read<int>('id'),
    email: row.read<String>('email'),
    fullName: row.read<String>('full_name'),
    role: row.read<String>('role'),
    status: row.read<String>('status'),
    balanceCop: row.read<int>('balance_cop'),
  );

  String _normalize(String value) => value.trim().toLowerCase();
}
