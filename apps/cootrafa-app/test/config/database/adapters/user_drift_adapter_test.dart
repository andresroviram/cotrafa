import 'package:core/security/credential_hasher.dart';
import 'package:feature_auth/domain/entities/demo_credentials.dart';
import 'package:drift/drift.dart' show QueryRow;
import 'package:drift/native.dart';
import 'package:cootrafa_app/config/database/cootrafa_database.dart';
import 'package:cootrafa_app/config/database/adapters/user_drift_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late CootrafaDatabase database;
  late UserDriftAdapter users;
  setUp(() async {
    database = CootrafaDatabase.forTesting(
      NativeDatabase.memory(),
      CredentialHasher(
        memoryKiB: 64,
        iterations: 1,
        saltFactory: () => List<int>.filled(16, 7),
      ),
    );
    users = UserDriftAdapter(database);
    await database.customSelect('SELECT 1').getSingle();
  });
  tearDown(() => database.close());

  test('admin CRUD rejects invalid identifiers or balance', () async {
    final created = await _create(users, ' CLIENT@EXAMPLE.COM ', 250);
    expect(created.value?.email, 'client@example.com');
    expect(created.value?.status, 'pendingActivation');
    expect(created.value?.balanceCop, 250);
    final row = await _user(database, created.value!.id);
    expect(row.readNullable<String>('password_hash'), isNull);
    expect(row.readNullable<String>('activation_code_hash'), isNull);
    expect((await users.listUsers(1)).value?.length, 2);
    expect(
      (await users.editProfile(
        1,
        created.value!.id,
        fullName: 'Edited',
      )).value?.fullName,
      'Edited',
    );
    expect(
      (await _create(users, DemoAdmin.email.toUpperCase(), 0)).error,
      UserError.identifierTaken,
    );
    await database.customStatement(
      "INSERT INTO login_identifiers VALUES ('reserved',${created.value!.id},'username')",
    );
    expect(
      (await _create(users, 'RESERVED', 0)).error,
      UserError.identifierTaken,
    );
    expect(
      (await _create(users, 'negative@example.com', -1)).error,
      UserError.invalidBalance,
    );
    expect((await users.listUsers(1)).value?.length, 2);
  });

  test('active client can view and edit only own name', () async {
    final client = (await _create(users, 'client@example.com', 75)).value!;
    await database.customStatement(
      "UPDATE users SET status='active' WHERE id=${client.id}",
    );
    expect(
      (await users.getUser(client.id, client.id)).value?.fullName,
      'Client',
    );
    expect(
      (await users.editProfile(
        client.id,
        client.id,
        fullName: 'Self',
      )).value?.fullName,
      'Self',
    );
    expect((await users.getUser(client.id, 1)).error, UserError.unauthorized);
    expect(
      (await users.editProfile(client.id, 1, fullName: 'Attack')).error,
      UserError.unauthorized,
    );
    expect((await users.listUsers(client.id)).error, UserError.unauthorized);
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
    expect((await users.deleteUser(1, client.id)).value, DeleteOutcome.deleted);
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
      (await users.deleteUser(1, origin.id)).value,
      DeleteOutcome.deactivated,
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
    expect((await users.deleteUser(1, 1)).error, UserError.demoAdminProtected);
    expect((await _user(database, 1)).read<String>('status'), 'active');
  });
}

Future<UserProfile> _activeClient(
  UserDriftAdapter users,
  CootrafaDatabase database,
  String email,
  int balance,
) async {
  final user = (await _create(users, email, balance)).value!;
  await database.customStatement(
    "UPDATE users SET status='active' WHERE id=${user.id}",
  );
  return user;
}

Future<UserResult<UserProfile>> _create(
  UserDriftAdapter users,
  String email,
  int balance,
) => users.createClient(
  1,
  email: email,
  fullName: 'Client',
  initialBalanceCop: balance,
);

Future<QueryRow> _user(CootrafaDatabase database, int id) =>
    database.customSelect('SELECT * FROM users WHERE id=$id').getSingle();

Future<int> _count(CootrafaDatabase database, String table, String where) =>
    database
        .customSelect('SELECT COUNT(*) AS count FROM $table WHERE $where')
        .map((row) => row.read<int>('count'))
        .getSingle();

String _transferSql(int origin, int destination) =>
    "INSERT INTO transfers VALUES ('history',$origin,$destination,10,'completed',NULL,1,'Origin','Destination')";
