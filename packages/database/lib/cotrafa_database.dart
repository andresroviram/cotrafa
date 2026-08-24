import 'package:core/database/connection/shared.dart';
import 'package:core/security/credential_hasher.dart';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

part 'cotrafa_database.g.dart';
part 'tables/addresses.dart';
part 'tables/local_session.dart';
part 'tables/login_identifiers.dart';
part 'tables/transfers.dart';
part 'tables/users.dart';

@DriftDatabase(
  tables: <Type>[Users, LoginIdentifiers, Addresses, Transfers, LocalSession],
)
@singleton
class CotrafaDatabase extends _$CotrafaDatabase {
  CotrafaDatabase(this._credentialHasher, this._seed)
    : super(connect('cotrafa'));

  CotrafaDatabase.forTesting(
    super.executor,
    this._credentialHasher, {
    this._seed = CotrafaDatabaseSeed.test,
  });

  final CredentialHasher _credentialHasher;
  final CotrafaDatabaseSeed _seed;

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator migrator) => migrator.createAll(),
    onUpgrade: (Migrator migrator, int from, int to) async {
      if (from < 2) {
        await migrator.addColumn(addresses, addresses.line2);
        await migrator.addColumn(addresses, addresses.state);
        await migrator.addColumn(addresses, addresses.postalCode);
        await migrator.addColumn(addresses, addresses.country);
      }
      if (from < 3) {
        await migrator.addColumn(users, users.firstName);
        await migrator.addColumn(users, users.lastName);
        await migrator.addColumn(users, users.birthDate);
        await migrator.addColumn(users, users.phone);
      }
    },
    beforeOpen: (_) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await _seedDemoAdmin();
    },
  );

  Future<void> _seedDemoAdmin() => transaction(() async {
    final User? existing = await (select(
      users,
    )..where((table) => table.id.equals(_seed.userId))).getSingleOrNull();
    if (existing != null) {
      final String firstName = _seedName(existing.firstName, _seed.firstName);
      final String lastName = _seedName(existing.lastName, _seed.lastName);
      final String fullName = '$firstName $lastName';
      if (existing.firstName == firstName &&
          existing.lastName == lastName &&
          existing.fullName == fullName) {
        return;
      }
      await (update(
        users,
      )..where((table) => table.id.equals(_seed.userId))).write(
        UsersCompanion(
          fullName: Value<String>(fullName),
          firstName: Value<String>(firstName),
          lastName: Value<String>(lastName),
          updatedAt: Value<int>(DateTime.now().millisecondsSinceEpoch),
        ),
      );
      return;
    }
    final String passwordHash = await _credentialHasher.hash(_seed.password);
    final int now = DateTime.now().millisecondsSinceEpoch;
    await into(users).insert(
      UsersCompanion.insert(
        id: Value<int>(_seed.userId),
        email: _seed.email,
        fullName: _seed.fullName,
        firstName: Value<String>(_seed.firstName),
        lastName: Value<String>(_seed.lastName),
        role: 'admin',
        status: 'active',
        passwordHash: Value<String>(passwordHash),
        balanceCop: const Value<int>(0),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await into(loginIdentifiers).insert(
      LoginIdentifiersCompanion.insert(
        normalized: _seed.email,
        userId: _seed.userId,
        kind: 'email',
      ),
    );
    await into(loginIdentifiers).insert(
      LoginIdentifiersCompanion.insert(
        normalized: _seed.username,
        userId: _seed.userId,
        kind: 'username',
      ),
    );
  });

  String _seedName(String? stored, String fallback) {
    final String normalized = stored?.trim() ?? '';
    return normalized.isEmpty ? fallback : normalized;
  }

  Future<void> setSessionUserId(int userId) =>
      into(localSession).insertOnConflictUpdate(
        LocalSessionCompanion.insert(slot: const Value<int>(1), userId: userId),
      );

  Future<int?> currentSessionUserId() =>
      (select(localSession)..where((table) => table.slot.equals(1)))
          .map((row) => row.userId)
          .getSingleOrNull();
}

@singleton
class CotrafaDatabaseSeed {
  @factoryMethod
  const CotrafaDatabaseSeed.demo()
    : this(
        userId: 1,
        email: 'admin@cotrafa.local',
        username: 'admin',
        firstName: 'Cotrafa Demo',
        lastName: 'Admin',
        password: 'CotrafaDemo2026!',
      );

  const CotrafaDatabaseSeed({
    required this.userId,
    required this.email,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.password,
  });

  static const test = CotrafaDatabaseSeed(
    userId: 1,
    email: 'test-admin@cotrafa.local',
    username: 'test-admin',
    firstName: 'Test',
    lastName: 'Admin',
    password: 'test-password',
  );

  final int userId;
  final String email;
  final String username;
  final String firstName;
  final String lastName;
  final String password;

  String get fullName => '$firstName $lastName';
}
