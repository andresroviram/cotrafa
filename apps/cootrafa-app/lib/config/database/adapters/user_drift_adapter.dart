import 'package:cootrafa_app/config/database/cootrafa_database.dart';
import 'package:drift/drift.dart';
import 'package:features/src/auth/auth.dart';

enum UserError {
  unauthorized,
  invalidBalance,
  identifierTaken,
  notFound,
  demoAdminProtected,
  storageFailure,
}

enum DeleteOutcome { deleted, deactivated }

final class UserResult<T> {
  const UserResult.ok(this.value) : error = null;
  const UserResult.failure(this.error) : value = null;
  final T? value;
  final UserError? error;
}

final class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.status,
    required this.balanceCop,
  });
  final int id;
  final String email;
  final String fullName;
  final String role;
  final String status;
  final int balanceCop;
}

final class UserDriftAdapter {
  UserDriftAdapter(this._database);
  final CootrafaDatabase _database;

  Future<UserResult<List<UserProfile>>> listUsers(
    int actorUserId,
  ) => _guard(() async {
    if (!await _isActiveAdmin(actorUserId)) {
      return const UserResult.failure(UserError.unauthorized);
    }
    final rows = await _database
        .customSelect(
          'SELECT id,email,full_name,role,status,balance_cop FROM users ORDER BY id',
        )
        .get();
    return UserResult.ok(rows.map(_profile).toList());
  });

  Future<UserResult<UserProfile>> getUser(int actorUserId, int userId) =>
      _guard(() async {
        final actor = await _user(actorUserId);
        if (!_canAccess(actor, userId)) {
          return const UserResult.failure(UserError.unauthorized);
        }
        final target = await _user(userId);
        return target == null
            ? const UserResult.failure(UserError.notFound)
            : UserResult.ok(_profile(target));
      });

  Future<UserResult<UserProfile>> createClient(
    int actorUserId, {
    required String email,
    required String fullName,
    required int initialBalanceCop,
  }) => _guard(
    () => _database.transaction(() async {
      if (!await _isActiveAdmin(actorUserId)) {
        return const UserResult.failure(UserError.unauthorized);
      }
      if (initialBalanceCop < 0) {
        return const UserResult.failure(UserError.invalidBalance);
      }
      final normalized = _normalize(email);
      if (await _identifierExists(normalized)) {
        return const UserResult.failure(UserError.identifierTaken);
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
      return UserResult.ok(_profile((await _user(id))!));
    }),
  );

  Future<UserResult<UserProfile>> editProfile(
    int actorUserId,
    int userId, {
    required String fullName,
  }) => _guard(
    () => _database.transaction(() async {
      final actor = await _user(actorUserId);
      if (!_canAccess(actor, userId)) {
        return const UserResult.failure(UserError.unauthorized);
      }
      if (await _user(userId) == null) {
        return const UserResult.failure(UserError.notFound);
      }
      await _database.customStatement(
        'UPDATE users SET full_name=?,updated_at=? WHERE id=?',
        <Object?>[fullName, DateTime.now().millisecondsSinceEpoch, userId],
      );
      return UserResult.ok(_profile((await _user(userId))!));
    }),
  );

  Future<UserResult<DeleteOutcome>> deleteUser(int actorUserId, int userId) =>
      _guard(
        () => _database.transaction(() async {
          if (!await _isActiveAdmin(actorUserId)) {
            return const UserResult.failure(UserError.unauthorized);
          }
          if (userId == DemoAdmin.userId) {
            return const UserResult.failure(UserError.demoAdminProtected);
          }
          if (await _user(userId) == null) {
            return const UserResult.failure(UserError.notFound);
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
            return const UserResult.ok(DeleteOutcome.deactivated);
          }
          await _database.customStatement(
            'DELETE FROM users WHERE id=?',
            <Object?>[userId],
          );
          return const UserResult.ok(DeleteOutcome.deleted);
        }),
      );

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

  Future<UserResult<T>> _guard<T>(
    Future<UserResult<T>> Function() action,
  ) async {
    try {
      return await action();
    } on Object {
      return const UserResult.failure(UserError.storageFailure);
    }
  }

  String _normalize(String value) => value.trim().toLowerCase();
}
