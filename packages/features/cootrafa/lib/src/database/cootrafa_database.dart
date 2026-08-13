import 'package:drift/drift.dart';
import 'package:features/src/security/credential_hasher.dart';

export 'package:features/src/security/credential_hasher.dart';

part 'cootrafa_database.g.dart';
part 'tables/addresses.dart';
part 'tables/local_session.dart';
part 'tables/login_identifiers.dart';
part 'tables/transfers.dart';
part 'tables/users.dart';

@DriftDatabase(
  tables: <Type>[Users, LoginIdentifiers, Addresses, Transfers, LocalSession],
)
class CootrafaDatabase extends _$CootrafaDatabase {
  CootrafaDatabase(super.executor, {CredentialHasher? credentialHasher})
    : _credentialHasher = credentialHasher ?? CredentialHasher();

  final CredentialHasher _credentialHasher;

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator migrator) async {
      await migrator.createAll();
      await customStatement(
        'CREATE UNIQUE INDEX one_primary_address_per_user '
        'ON addresses (user_id) WHERE is_primary = 1',
      );
      await customStatement(
        'CREATE INDEX addresses_user_idx ON addresses (user_id)',
      );
      await customStatement(
        'CREATE INDEX transfers_origin_idx ON transfers (origin_user_id)',
      );
      await customStatement(
        'CREATE INDEX transfers_destination_idx ON transfers (destination_user_id)',
      );
    },
    onUpgrade: (Migrator migrator, int from, int to) async {
      if (from == 1 && to == 2) {
        await migrator.addColumn(addresses, addresses.line2);
        await migrator.addColumn(addresses, addresses.state);
        await migrator.addColumn(addresses, addresses.postalCode);
        await migrator.addColumn(addresses, addresses.country);
        return;
      }
      throw StateError('No migration path registered from $from to $to.');
    },
    beforeOpen: (_) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await _seedDemoAdmin();
    },
  );

  Future<void> _seedDemoAdmin() => transaction(() async {
    final int count = await customSelect(
      'SELECT COUNT(*) AS count FROM users WHERE id = ?',
      variables: <Variable<Object>>[const Variable<int>(DemoAdmin.userId)],
    ).map((QueryRow row) => row.read<int>('count')).getSingle();
    if (count == 1) return;
    final String passwordHash = await _credentialHasher.hash(
      DemoAdmin.password,
    );
    final int now = DateTime.now().millisecondsSinceEpoch;
    await customStatement(
      'INSERT INTO users '
      '(id, email, full_name, role, status, password_hash, balance_cop, created_at, updated_at) '
      "VALUES (?, ?, ?, 'admin', 'active', ?, 0, ?, ?)",
      <Object?>[
        DemoAdmin.userId,
        DemoAdmin.email,
        DemoAdmin.fullName,
        passwordHash,
        now,
        now,
      ],
    );
    await customStatement(
      "INSERT INTO login_identifiers (normalized, user_id, kind) VALUES (?, ?, 'email')",
      <Object?>[DemoAdmin.email, DemoAdmin.userId],
    );
  });

  Future<void> setSessionUserId(int userId) => customStatement(
    'INSERT INTO local_session (slot, user_id) VALUES (1, ?) '
    'ON CONFLICT(slot) DO UPDATE SET user_id = excluded.user_id',
    <Object?>[userId],
  );

  Future<int?> currentSessionUserId() => customSelect(
    'SELECT user_id FROM local_session WHERE slot = 1',
  ).map((QueryRow row) => row.read<int>('user_id')).getSingleOrNull();
}

abstract final class DemoAdmin {
  static const int userId = 1;
  static const String email = 'admin@cootrafa.local';
  static const String fullName = 'Cootrafa Demo Admin';
  static const String password = 'CootrafaDemo2026!';
}
