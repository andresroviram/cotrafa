import 'package:core/errors/error.dart';
import 'package:core/security/credential_hasher.dart';
import 'package:drift/drift.dart' show QueryRow;
import 'package:drift/native.dart';
import 'package:cotrafa_database/cotrafa_database.dart';
import 'package:feature_user/data/datasources/user_local_datasource.dart';
import 'package:feature_user/data/models/delete_outcome_model.dart';
import 'package:feature_user/data/models/user_profile_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late CotrafaDatabase database;
  late UserLocalDatasource users;
  setUp(() async {
    database = CotrafaDatabase.forTesting(
      NativeDatabase.memory(),
      CredentialHasher(
        memoryKiB: 64,
        iterations: 1,
        saltFactory: () => List<int>.filled(16, 7),
      ),
      seed: _demoSeed,
    );
    users = UserLocalDatasource(database, CotrafaDatabaseSeed.test);
    await database.customSelect('SELECT 1').getSingle();
  });
  tearDown(() => database.close());

  test('maps the demo administrator canonical name fields', () async {
    final admin = await users.getUser(_demoSeed.userId, _demoSeed.userId);

    expect(admin.firstName, _demoSeed.firstName);
    expect(admin.lastName, _demoSeed.lastName);
    expect(admin.fullName, _demoSeed.fullName);
    expect(admin.username, _demoSeed.username);
    expect(admin.toEntity().displayName, _demoSeed.fullName);
  });

  test('admin CRUD persists normalized use-case input', () async {
    final created = await _create(users, 'client@example.com', 250);
    expect(created.email, 'client@example.com');
    expect(created.firstName, 'Client');
    expect(created.lastName, 'User');
    expect(created.birthDate, isNull);
    expect(created.phone, isNull);
    expect(created.status, 'pendingActivation');
    expect(created.balanceCop, 250);
    final row = await _user(database, created.id);
    expect(row.readNullable<String>('password_hash'), isNull);
    expect(row.readNullable<String>('activation_code_hash'), isNull);
    expect((await users.listUsers(1)).length, 2);
    final updated = await users.editProfile(
      1,
      created.id,
      firstName: 'Sofia',
      lastName: 'Rovira',
      birthDate: DateTime(2000, 6, 15),
      phone: '3001234567',
    );
    expect(updated.fullName, 'Sofia Rovira');
    expect(updated.firstName, 'Sofia');
    expect(updated.lastName, 'Rovira');
    expect(updated.birthDate, DateTime.utc(2000, 6, 15));
    expect(updated.phone, '3001234567');
    await expectLater(
      _create(users, CotrafaDatabaseSeed.test.email, 0),
      throwsA(isA<DuplicateException>()),
    );
    await database.customStatement(
      "INSERT INTO login_identifiers VALUES ('reserved',${created.id},'username')",
    );
    expect((await users.getUser(1, created.id)).username, 'reserved');
    await expectLater(
      _create(users, 'reserved', 0),
      throwsA(isA<DuplicateException>()),
    );
    expect((await users.listUsers(1)).length, 2);
  });

  test('active client can view and edit only own profile', () async {
    final client = await _create(users, 'client@example.com', 75);
    await database.customStatement(
      "UPDATE users SET status='active' WHERE id=${client.id}",
    );
    expect((await users.getUser(client.id, client.id)).email, client.email);
    expect(
      (await users.editProfile(
        client.id,
        client.id,
        firstName: 'Self',
        lastName: 'User',
        birthDate: null,
        phone: null,
      )).fullName,
      'Self User',
    );
    await expectLater(
      users.getUser(client.id, 1),
      throwsA(isA<UnauthorizedException>()),
    );
    await expectLater(
      users.editProfile(
        client.id,
        1,
        firstName: 'Attack',
        lastName: 'Admin',
        birthDate: null,
        phone: null,
      ),
      throwsA(isA<UnauthorizedException>()),
    );
    await expectLater(
      users.createClient(
        client.id,
        email: 'forbidden@example.com',
        firstName: 'Forbidden',
        lastName: 'Client',
        birthDate: null,
        phone: null,
        initialBalanceCop: 1000,
      ),
      throwsA(isA<UnauthorizedException>()),
    );
    await expectLater(
      users.listUsers(client.id),
      throwsA(isA<UnauthorizedException>()),
    );
    await expectLater(users.getUser(1, 999), throwsA(isA<NotFoundException>()));
    final unchanged = await _user(database, client.id);
    expect(unchanged.read<String>('role'), 'client');
    expect(unchanged.read<String>('status'), 'active');
    expect(unchanged.read<int>('balance_cop'), 75);
  });

  test('hard delete cascades identifiers, addresses, and session', () async {
    final client = await _activeClient(
      users,
      database,
      'delete@example.com',
      0,
    );
    await database.customStatement(
      "INSERT INTO addresses (user_id,line1,city,label,is_primary) VALUES (${client.id},'One','Medellin','Home',1)",
    );
    await database.setSessionUserId(client.id);
    expect(await users.deleteUser(1, client.id), DeleteOutcomeModel.deleted);
    expect(await _count(database, 'users', 'id=${client.id}'), 0);
    expect(
      await _count(database, 'login_identifiers', 'user_id=${client.id}'),
      0,
    );
    expect(await _count(database, 'addresses', 'user_id=${client.id}'), 0);
    expect(await database.currentSessionUserId(), isNull);
  });

  test('referenced user deactivates and admin stays protected', () async {
    final origin = await _activeClient(
      users,
      database,
      'origin@example.com',
      100,
    );
    final destination = await _activeClient(
      users,
      database,
      'destination@example.com',
      0,
    );
    await database.customStatement(
      "UPDATE users SET password_hash='hash',activation_code_hash='code' WHERE id=${origin.id}",
    );
    await database.setSessionUserId(origin.id);
    await database.customStatement(_transferSql(origin.id, destination.id));
    expect(
      await users.deleteUser(1, origin.id),
      DeleteOutcomeModel.deactivated,
    );
    final retained = await _user(database, origin.id);
    expect(retained.read<String>('status'), 'inactive');
    expect(retained.read<int>('balance_cop'), 100);
    expect(retained.readNullable<String>('password_hash'), isNull);
    expect(retained.readNullable<String>('activation_code_hash'), isNull);
    expect(
      await _count(database, 'transfers', 'origin_user_id=${origin.id}'),
      1,
    );
    expect(
      await _count(database, 'login_identifiers', 'user_id=${origin.id}'),
      1,
    );
    expect(await database.currentSessionUserId(), isNull);
    await expectLater(
      users.deleteUser(1, 1),
      throwsA(
        isA<ValidationException>().having(
          (error) => error.message,
          'message',
          'Demo admin cannot be deleted.',
        ),
      ),
    );
    expect((await _user(database, 1)).read<String>('status'), 'active');
  });
}

Future<UserProfileModel> _activeClient(
  UserLocalDatasource users,
  CotrafaDatabase database,
  String email,
  int balance,
) async {
  final user = await _create(users, email, balance);
  await database.customStatement(
    "UPDATE users SET status='active' WHERE id=${user.id}",
  );
  return user;
}

Future<UserProfileModel> _create(
  UserLocalDatasource users,
  String email,
  int balance,
) => users.createClient(
  1,
  email: email,
  firstName: 'Client',
  lastName: 'User',
  birthDate: null,
  phone: null,
  initialBalanceCop: balance,
);

Future<QueryRow> _user(CotrafaDatabase database, int id) =>
    database.customSelect('SELECT * FROM users WHERE id=$id').getSingle();

Future<int> _count(CotrafaDatabase database, String table, String where) =>
    database
        .customSelect('SELECT COUNT(*) AS count FROM $table WHERE $where')
        .map((row) => row.read<int>('count'))
        .getSingle();

String _transferSql(int origin, int destination) =>
    "INSERT INTO transfers VALUES ('history',$origin,$destination,10,'completed',NULL,1,'Origin','Destination')";

const _demoSeed = CotrafaDatabaseSeed.test;
