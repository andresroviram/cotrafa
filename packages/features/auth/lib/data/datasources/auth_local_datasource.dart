import 'package:cotrafa_database/cotrafa_database.dart';
import 'package:core/errors/error.dart';
import 'package:core/security/activation_code_generator.dart';
import 'package:core/security/credential_hasher.dart';
import 'package:drift/drift.dart';
import 'package:feature_auth/data/models/auth_identity_model.dart';
import 'package:injectable/injectable.dart';

abstract interface class IAuthLocalDatasource {
  Future<String> issueActivationCode(int actorUserId, String email);

  Future<AuthIdentityModel> activate(
    String email,
    String code,
    String username,
    String password,
  );

  Future<AuthIdentityModel> login(String identifier, String password);
  Future<AuthIdentityModel> loginDemoAdmin();
  Future<AuthIdentityModel?> restore();
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
            actor.role != 'admin' ||
            actor.status != 'active') {
          throw const UnauthorizedException();
        }
        final client = await _userByIdentifier(clientEmail, kind: 'email');
        if (client == null ||
            client.role != 'client' ||
            client.status != 'pendingActivation') {
          throw const ValidationException(
            message: 'Client is not pending activation.',
          );
        }
        final code = _activationCodeGenerator.generate();
        final hash = await _credentialHasher.hash(code);
        await (_database.update(
          _database.users,
        )..where((table) => table.id.equals(client.id))).write(
          UsersCompanion(
            activationCodeHash: Value(hash),
            updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );
        return code;
      });

  @override
  Future<AuthIdentityModel> activate(
    String email,
    String code,
    String username,
    String password,
  ) => _database.transaction(() async {
    final client = await _userByIdentifier(email, kind: 'email');
    final codeHash = client?.activationCodeHash;
    if (client == null ||
        client.role != 'client' ||
        client.status != 'pendingActivation' ||
        codeHash == null ||
        !await _credentialHasher.verify(code, codeHash)) {
      throw const AuthException();
    }
    if (await _userByIdentifier(username) != null) {
      throw const DuplicateException();
    }
    final userId = client.id;
    final passwordHash = await _credentialHasher.hash(password);
    await _database
        .into(_database.loginIdentifiers)
        .insert(
          LoginIdentifiersCompanion.insert(
            normalized: username,
            userId: userId,
            kind: 'username',
          ),
        );
    await (_database.update(
      _database.users,
    )..where((table) => table.id.equals(userId))).write(
      UsersCompanion(
        passwordHash: Value(passwordHash),
        activationCodeHash: const Value(null),
        status: const Value('active'),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
    await _database.setSessionUserId(userId);
    return AuthIdentityModel(userId: userId, role: 'client');
  });

  @override
  Future<AuthIdentityModel> login(String identifier, String password) =>
      _database.transaction(() async {
        final user = await _userByIdentifier(identifier);
        final passwordHash = user?.passwordHash;
        if (user == null ||
            user.status != 'active' ||
            passwordHash == null ||
            !await _credentialHasher.verify(password, passwordHash)) {
          throw const AuthException();
        }
        final identity = _identity(user);
        await _database.setSessionUserId(identity.userId);
        return identity;
      });

  @override
  Future<AuthIdentityModel> loginDemoAdmin() =>
      login(_databaseSeed.email, _databaseSeed.password);

  @override
  Future<AuthIdentityModel?> restore() async {
    final userId = await _database.currentSessionUserId();
    final user = userId == null ? null : await _userById(userId);
    if (user == null || user.status != 'active') {
      await _database.delete(_database.localSession).go();
      return null;
    }
    return _identity(user);
  }

  @override
  Future<void> logout() async {
    await _database.delete(_database.localSession).go();
  }

  Future<User?> _userById(int id) => (_database.select(
    _database.users,
  )..where((table) => table.id.equals(id))).getSingleOrNull();

  Future<User?> _userByIdentifier(String normalized, {String? kind}) async {
    final identifiers = _database.loginIdentifiers;
    final users = _database.users;
    final predicate = kind == null
        ? identifiers.normalized.equals(normalized)
        : identifiers.normalized.equals(normalized) &
              identifiers.kind.equals(kind);
    final query = _database.select(users).join([
      innerJoin(identifiers, identifiers.userId.equalsExp(users.id)),
    ])..where(predicate);
    return (await query.getSingleOrNull())?.readTable(users);
  }

  AuthIdentityModel _identity(User user) =>
      AuthIdentityModel(userId: user.id, role: user.role);
}
