import 'package:cotrafa_database/cotrafa_database.dart';
import 'package:core/errors/error.dart';
import 'package:core/security/activation_code_generator.dart';
import 'package:core/security/credential_hasher.dart';
import 'package:drift/drift.dart';
import 'package:feature_auth/domain/entities/auth_identity.dart';
import 'package:injectable/injectable.dart';

abstract interface class IAuthLocalDatasource {
  Future<String> issueActivationCode(int actorUserId, String email);

  Future<AuthIdentity> activate(
    String email,
    String code,
    String username,
    String password,
  );

  Future<AuthIdentity> login(String identifier, String password);
  Future<AuthIdentity> loginDemoAdmin();
  Future<AuthIdentity?> restore();
  Future<void> logout();
}

@LazySingleton(as: IAuthLocalDatasource)
final class AuthLocalDatasource implements IAuthLocalDatasource {
  AuthLocalDatasource(
    this._database,
    this._credentialHasher,
    this._activationCodeGenerator,
    this._databaseSeed,
  );

  final CotrafaDatabase _database;
  final CredentialHasher _credentialHasher;
  final ActivationCodeGenerator _activationCodeGenerator;
  final CotrafaDatabaseSeed _databaseSeed;

  @override
  Future<String> issueActivationCode(int actorUserId, String clientEmail) =>
      _database.transaction(() async {
        final actor = await _userById(actorUserId);
        if (actor == null ||
            actor.read<String>('role') != 'admin' ||
            actor.read<String>('status') != 'active') {
          throw const UnauthorizedException();
        }
        final client = await _userByIdentifier(
          _normalize(clientEmail),
          kind: 'email',
        );
        if (client == null ||
            client.read<String>('role') != 'client' ||
            client.read<String>('status') != 'pendingActivation') {
          throw const ValidationException(
            message: 'Client is not pending activation.',
          );
        }
        final code = _activationCodeGenerator.generate();
        final hash = await _credentialHasher.hash(code);
        await _database.customStatement(
          'UPDATE users SET activation_code_hash=?,updated_at=? WHERE id=?',
          <Object?>[
            hash,
            DateTime.now().millisecondsSinceEpoch,
            client.read<int>('id'),
          ],
        );
        return code;
      });

  @override
  Future<AuthIdentity> activate(
    String email,
    String code,
    String username,
    String password,
  ) => _database.transaction(() async {
    final client = await _userByIdentifier(_normalize(email), kind: 'email');
    final codeHash = client?.readNullable<String>('activation_code_hash');
    if (client == null ||
        client.read<String>('role') != 'client' ||
        client.read<String>('status') != 'pendingActivation' ||
        codeHash == null ||
        !await _credentialHasher.verify(code, codeHash)) {
      throw const AuthException();
    }
    final normalizedUsername = _normalize(username);
    if (await _userByIdentifier(normalizedUsername) != null) {
      throw const DuplicateException();
    }
    final userId = client.read<int>('id');
    final passwordHash = await _credentialHasher.hash(password);
    await _database.customStatement(
      "INSERT INTO login_identifiers VALUES (?,?,'username')",
      <Object?>[normalizedUsername, userId],
    );
    await _database.customStatement(
      "UPDATE users SET password_hash=?,activation_code_hash=NULL,status='active',updated_at=? WHERE id=?",
      <Object?>[passwordHash, DateTime.now().millisecondsSinceEpoch, userId],
    );
    await _database.setSessionUserId(userId);
    return AuthIdentity(userId: userId, role: 'client');
  });

  @override
  Future<AuthIdentity> login(String identifier, String password) =>
      _database.transaction(() async {
        final user = await _userByIdentifier(_normalize(identifier));
        final passwordHash = user?.readNullable<String>('password_hash');
        if (user == null ||
            user.read<String>('status') != 'active' ||
            passwordHash == null ||
            !await _credentialHasher.verify(password, passwordHash)) {
          throw const AuthException();
        }
        final identity = _identity(user);
        await _database.setSessionUserId(identity.userId);
        return identity;
      });

  @override
  Future<AuthIdentity> loginDemoAdmin() =>
      login(_databaseSeed.email, _databaseSeed.password);

  @override
  Future<AuthIdentity?> restore() async {
    final userId = await _database.currentSessionUserId();
    final user = userId == null ? null : await _userById(userId);
    if (user == null || user.read<String>('status') != 'active') {
      await _database.customStatement('DELETE FROM local_session');
      return null;
    }
    return _identity(user);
  }

  @override
  Future<void> logout() =>
      _database.customStatement('DELETE FROM local_session');

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

  String _normalize(String value) => value.trim().toLowerCase();
}
