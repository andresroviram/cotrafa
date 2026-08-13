import 'dart:math';

import 'package:drift/drift.dart';
import 'package:equatable/equatable.dart';
import 'package:features/src/database/cootrafa_database.dart';

enum AuthError {
  unauthorized,
  clientNotPending,
  identifierTaken,
  invalidCredentials,
  storageFailure,
}

final class AuthResult<T> {
  const AuthResult.ok(this.value) : error = null;
  const AuthResult.failure(this.error) : value = null;

  final T? value;
  final AuthError? error;
}

final class AuthIdentity extends Equatable {
  const AuthIdentity({required this.userId, required this.role});
  final int userId;
  final String role;

  @override
  List<Object> get props => <Object>[userId, role];
}

abstract interface class ActivationCodeGenerator {
  String generate();
}

final class SecureActivationCodeGenerator implements ActivationCodeGenerator {
  SecureActivationCodeGenerator([Random? random])
    : _random = random ?? Random.secure();
  final Random _random;

  @override
  String generate() => (_random.nextInt(900000) + 100000).toString();
}

final class AuthService {
  AuthService(
    this._database, {
    CredentialHasher? credentialHasher,
    ActivationCodeGenerator? codeGenerator,
  }) : _hasher = credentialHasher ?? CredentialHasher(),
       _codes = codeGenerator ?? SecureActivationCodeGenerator();

  final CootrafaDatabase _database;
  final CredentialHasher _hasher;
  final ActivationCodeGenerator _codes;

  Future<AuthResult<String>> issueActivationCode(
    int actorUserId,
    String clientEmail,
  ) => _guard(
    () => _database.transaction(() async {
      final actor = await _userById(actorUserId);
      if (actor == null ||
          actor.read<String>('role') != 'admin' ||
          actor.read<String>('status') != 'active') {
        return const AuthResult.failure(AuthError.unauthorized);
      }
      final client = await _userByIdentifier(
        _normalize(clientEmail),
        kind: 'email',
      );
      if (client == null ||
          client.read<String>('role') != 'client' ||
          client.read<String>('status') != 'pendingActivation') {
        return const AuthResult.failure(AuthError.clientNotPending);
      }
      final code = _codes.generate();
      final hash = await _hasher.hash(code);
      await _database.customStatement(
        'UPDATE users SET activation_code_hash=?,updated_at=? WHERE id=?',
        <Object?>[
          hash,
          DateTime.now().millisecondsSinceEpoch,
          client.read<int>('id'),
        ],
      );
      return AuthResult.ok(code);
    }),
  );

  Future<AuthResult<AuthIdentity>> activate(
    String email,
    String code,
    String username,
    String password,
  ) => _guard(
    () => _database.transaction(() async {
      final client = await _userByIdentifier(_normalize(email), kind: 'email');
      final codeHash = client?.readNullable<String>('activation_code_hash');
      if (client == null ||
          client.read<String>('role') != 'client' ||
          client.read<String>('status') != 'pendingActivation' ||
          codeHash == null ||
          !await _hasher.verify(code, codeHash)) {
        return const AuthResult.failure(AuthError.invalidCredentials);
      }
      final normalizedUsername = _normalize(username);
      if (await _userByIdentifier(normalizedUsername) != null) {
        return const AuthResult.failure(AuthError.identifierTaken);
      }
      final userId = client.read<int>('id');
      final passwordHash = await _hasher.hash(password);
      await _database.customStatement(
        "INSERT INTO login_identifiers VALUES (?,?,'username')",
        <Object?>[normalizedUsername, userId],
      );
      await _database.customStatement(
        "UPDATE users SET password_hash=?,activation_code_hash=NULL,status='active',updated_at=? WHERE id=?",
        <Object?>[passwordHash, DateTime.now().millisecondsSinceEpoch, userId],
      );
      return AuthResult.ok(AuthIdentity(userId: userId, role: 'client'));
    }),
  );

  Future<AuthResult<AuthIdentity>> login(String identifier, String password) =>
      _guard(
        () => _database.transaction(() async {
          final user = await _userByIdentifier(_normalize(identifier));
          final passwordHash = user?.readNullable<String>('password_hash');
          if (user == null ||
              user.read<String>('status') != 'active' ||
              passwordHash == null ||
              !await _hasher.verify(password, passwordHash)) {
            return const AuthResult.failure(AuthError.invalidCredentials);
          }
          final identity = _identity(user);
          await _database.setSessionUserId(identity.userId);
          return AuthResult.ok(identity);
        }),
      );

  Future<AuthResult<AuthIdentity?>> restore() => _guard(() async {
    final userId = await _database.currentSessionUserId();
    final user = userId == null ? null : await _userById(userId);
    if (user == null || user.read<String>('status') != 'active') {
      await _database.customStatement('DELETE FROM local_session');
      return const AuthResult.ok(null);
    }
    return AuthResult.ok(_identity(user));
  });

  Future<AuthResult<void>> logout() => _guard(() async {
    await _database.customStatement('DELETE FROM local_session');
    return const AuthResult.ok(null);
  });

  Future<QueryRow?> _userById(int id) => _database
      .customSelect(
        'SELECT id,role,status,password_hash,activation_code_hash FROM users WHERE id=?',
        variables: <Variable<Object>>[Variable<int>(id)],
      )
      .getSingleOrNull();

  Future<QueryRow?> _userByIdentifier(
    String normalized, {
    String? kind,
  }) => _database
      .customSelect(
        'SELECT u.id,u.role,u.status,u.password_hash,u.activation_code_hash '
        'FROM login_identifiers i JOIN users u ON u.id=i.user_id '
        'WHERE i.normalized=?${kind == null ? '' : ' AND i.kind=?'}',
        variables: <Variable<Object>>[
          Variable<String>(normalized),
          if (kind != null) Variable<String>(kind),
        ],
      )
      .getSingleOrNull();

  AuthIdentity _identity(QueryRow user) => AuthIdentity(
    userId: user.read<int>('id'),
    role: user.read<String>('role'),
  );

  Future<AuthResult<T>> _guard<T>(
    Future<AuthResult<T>> Function() action,
  ) async {
    try {
      return await action();
    } on Object {
      return const AuthResult.failure(AuthError.storageFailure);
    }
  }

  String _normalize(String value) => value.trim().toLowerCase();
}
