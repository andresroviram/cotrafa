import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';

part 'cootrafa_database.g.dart';

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get email => text()();
  TextColumn get fullName => text()();
  TextColumn get role =>
      text().customConstraint("NOT NULL CHECK (role IN ('admin', 'client'))")();
  TextColumn get status => text().customConstraint(
    "NOT NULL CHECK (status IN ('pendingActivation', 'active', 'inactive'))",
  )();
  TextColumn get passwordHash => text().nullable()();
  TextColumn get activationCodeHash => text().nullable()();
  IntColumn get balanceCop => integer().customConstraint(
    'NOT NULL DEFAULT 0 CHECK (balance_cop >= 0)',
  )();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}

class LoginIdentifiers extends Table {
  TextColumn get normalized => text()();
  IntColumn get userId =>
      integer().references(Users, #id, onDelete: KeyAction.cascade)();
  TextColumn get kind => text().customConstraint(
    "NOT NULL CHECK (kind IN ('email', 'username'))",
  )();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{normalized};

  @override
  List<Set<Column<Object>>> get uniqueKeys => <Set<Column<Object>>>[
    <Column<Object>>{userId, kind},
  ];
}

class Addresses extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get userId =>
      integer().references(Users, #id, onDelete: KeyAction.cascade)();
  TextColumn get line1 => text()();
  TextColumn get city => text()();
  TextColumn get label => text()();
  BoolColumn get isPrimary => boolean().withDefault(const Constant(false))();
}

class Transfers extends Table {
  TextColumn get id => text()();
  @ReferenceName('originTransfers')
  IntColumn get originUserId =>
      integer().references(Users, #id, onDelete: KeyAction.restrict)();
  @ReferenceName('destinationTransfers')
  IntColumn get destinationUserId =>
      integer().references(Users, #id, onDelete: KeyAction.restrict)();
  IntColumn get amountCop =>
      integer().customConstraint('NOT NULL CHECK (amount_cop > 0)')();
  TextColumn get status =>
      text().customConstraint("NOT NULL CHECK (status = 'completed')")();
  TextColumn get description => text().nullable()();
  IntColumn get createdAt => integer()();
  TextColumn get originSnapshot => text()();
  TextColumn get destinationSnapshot => text()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};

  @override
  List<String> get customConstraints => <String>[
    'CHECK (origin_user_id <> destination_user_id)',
  ];
}

class LocalSession extends Table {
  IntColumn get slot =>
      integer().customConstraint('NOT NULL CHECK (slot = 1)')();
  IntColumn get userId =>
      integer().references(Users, #id, onDelete: KeyAction.restrict)();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{slot};
}

@DriftDatabase(
  tables: <Type>[Users, LoginIdentifiers, Addresses, Transfers, LocalSession],
)
class CootrafaDatabase extends _$CootrafaDatabase {
  CootrafaDatabase(super.executor, {CredentialHasher? credentialHasher})
    : _credentialHasher = credentialHasher ?? CredentialHasher();

  final CredentialHasher _credentialHasher;

  @override
  int get schemaVersion => 1;

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
    onUpgrade: (Migrator _, int from, int to) async {
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

class CredentialHasher {
  CredentialHasher({
    this.memoryKiB = 19456,
    this.iterations = 2,
    this.parallelism = 1,
    this.hashLength = 32,
    List<int> Function()? saltFactory,
  }) : _saltFactory = saltFactory ?? _secureSalt;

  final int memoryKiB;
  final int iterations;
  final int parallelism;
  final int hashLength;
  final List<int> Function() _saltFactory;

  Future<String> hash(String secret) async {
    final List<int> salt = _saltFactory();
    final List<int> bytes = await _derive(secret, salt);
    return '\$argon2id\$v=19\$m=$memoryKiB,t=$iterations,p=$parallelism\$'
        '${base64UrlEncode(salt)}\$${base64UrlEncode(bytes)}';
  }

  Future<bool> verify(String secret, String encoded) async {
    final List<String> parts = encoded.split(r'$');
    if (parts.length != 6 || parts[1] != 'argon2id' || parts[2] != 'v=19') {
      return false;
    }
    final Map<String, int> parameters = <String, int>{
      for (final String item in parts[3].split(','))
        item.split('=').first: int.parse(item.split('=').last),
    };
    final CredentialHasher verifier = CredentialHasher(
      memoryKiB: parameters['m']!,
      iterations: parameters['t']!,
      parallelism: parameters['p']!,
      hashLength: base64Url.decode(parts[5]).length,
      saltFactory: () => base64Url.decode(parts[4]),
    );
    final List<int> actual = await verifier._derive(
      secret,
      base64Url.decode(parts[4]),
    );
    final List<int> expected = base64Url.decode(parts[5]);
    int difference = actual.length ^ expected.length;
    for (
      int index = 0;
      index < actual.length && index < expected.length;
      index++
    ) {
      difference |= actual[index] ^ expected[index];
    }
    return difference == 0;
  }

  Future<List<int>> _derive(String secret, List<int> salt) async {
    final SecretKey key = await Argon2id(
      parallelism: parallelism,
      memory: memoryKiB,
      iterations: iterations,
      hashLength: hashLength,
    ).deriveKey(secretKey: SecretKey(utf8.encode(secret)), nonce: salt);
    return key.extractBytes();
  }

  static List<int> _secureSalt() {
    final Random random = Random.secure();
    return List<int>.generate(16, (_) => random.nextInt(256));
  }
}
