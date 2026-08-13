import 'dart:io';

import 'package:drift/drift.dart' show QueryRow, Variable;
import 'package:drift/native.dart';
import 'package:features/src/database/cootrafa_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('hashes credentials with Argon2id', () async {
    final hasher = CredentialHasher();
    final stopwatch = Stopwatch()..start();
    final encoded = await hasher.hash('temporary-password');
    stopwatch.stop();
    expect(encoded, startsWith(r'$argon2id$v=19$'));
    expect(encoded, contains(r'$m=19456,t=2,p=1$'));
    expect(encoded, isNot(contains('temporary-password')));
    expect(await hasher.verify('temporary-password', encoded), isTrue);
    expect(await hasher.verify('wrong-password', encoded), isFalse);
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 5)));
  });
  group('schema v1', () {
    late CootrafaDatabase database;
    setUp(() async {
      database = _memoryDatabase();
      await database.customSelect('SELECT 1').getSingle();
    });
    tearDown(() => database.close());
    test('seeds one admin and enforces identity constraints', () async {
      final row = await _one(
        database,
        'SELECT role,status,balance_cop,password_hash,activation_code_hash '
        'FROM users WHERE id = ?',
        variables: [const Variable<int>(DemoAdmin.userId)],
      );
      expect(row.read<String>('role'), 'admin');
      expect(row.read<String>('status'), 'active');
      expect(row.read<int>('balance_cop'), 0);
      expect(row.read<String>('password_hash'), startsWith(r'$argon2id$'));
      expect(row.read<String>('password_hash'), isNot(DemoAdmin.password));
      expect(row.readNullable<String>('activation_code_hash'), isNull);
      for (final values in <String>[
        "'owner','active',0",
        "'client','blocked',0",
        "'client','active',-1",
      ]) {
        await _fails(database, _userSql(values));
      }
      await database.customStatement(
        "INSERT INTO users VALUES (2,'client@example.com','Client','client',"
        "'pendingActivation',NULL,NULL,50,1,1)",
      );
      await database.customStatement(
        _identifierSql('client@example.com', 'email'),
      );
      await _fails(database, _identifierSql('client@example.com', 'username'));
      await _fails(database, _identifierSql('client2@example.com', 'email'));
      await _fails(database, _identifierSql('invalid', 'phone'));
    });
    test('enforces address and immutable receipt storage', () async {
      await _insertClient(database, 2, 'origin@example.com');
      await _insertClient(database, 3, 'destination@example.com');
      await database.customStatement(_addressSql('First', 'Home'));
      await _fails(database, _addressSql('Second', 'Work'));
      await _fails(database, _transferSql(amount: -1));
      await _fails(database, _transferSql(amount: 1, status: 'pending'));
      await _fails(database, _transferSql(amount: 1, destination: 2));
      await database.customStatement(_transferSql(amount: 10));
      await _fails(database, 'DELETE FROM users WHERE id = 2');
      final columns = await _columns(database, 'transfers');
      expect(
        columns,
        containsAll(<String>{'origin_snapshot', 'destination_snapshot'}),
      );
      expect(columns.where((name) => name.contains('address')), isEmpty);
      await database.customStatement(
        "UPDATE users SET full_name='Changed' WHERE id=2",
      );
      final receipt = await _one(
        database,
        "SELECT origin_snapshot FROM transfers WHERE id='transfer-10-completed-3'",
      );
      expect(receipt.read<String>('origin_snapshot'), 'Origin');
    });
  });
  test('reopens without data loss and stores only session userId', () async {
    final directory = await Directory.systemTemp.createTemp('cootrafa-db-');
    final file = File('${directory.path}/cootrafa.sqlite');
    final first = CootrafaDatabase(
      NativeDatabase(file),
      credentialHasher: _fastHasher(),
    );
    await first.setSessionUserId(DemoAdmin.userId);
    await first.close();
    final reopened = CootrafaDatabase(
      NativeDatabase(file),
      credentialHasher: _fastHasher(),
    );
    expect(await reopened.currentSessionUserId(), DemoAdmin.userId);
    final adminCount = await _one(
      reopened,
      "SELECT COUNT(*) AS count FROM users WHERE role='admin'",
    );
    expect(adminCount.read<int>('count'), 1);
    expect(await _columns(reopened, 'local_session'), <String>{
      'slot',
      'user_id',
    });
    expect(
      await _columns(reopened, 'users'),
      isNot(containsAll(<String>{'password', 'activation_code'})),
    );
    expect(reopened.schemaVersion, 2);
    await reopened.close();
    await directory.delete(recursive: true);
  });
}

CootrafaDatabase _memoryDatabase() =>
    CootrafaDatabase(NativeDatabase.memory(), credentialHasher: _fastHasher());
CredentialHasher _fastHasher() => CredentialHasher(
  memoryKiB: 64,
  iterations: 1,
  saltFactory: () => List<int>.filled(16, 7),
);
Future<QueryRow> _one(
  CootrafaDatabase database,
  String sql, {
  List<Variable<Object>> variables = const [],
}) => database.customSelect(sql, variables: variables).getSingle();
Future<Set<String>> _columns(CootrafaDatabase database, String table) async =>
    (await database.customSelect('PRAGMA table_info($table)').get())
        .map((row) => row.read<String>('name'))
        .toSet();
Future<void> _fails(CootrafaDatabase database, String sql) async =>
    expectLater(database.customStatement(sql), throwsA(isA<Exception>()));
Future<void> _insertClient(CootrafaDatabase database, int id, String email) =>
    database.customStatement(
      "INSERT INTO users VALUES ($id,'$email','Client $id','client','active',"
      "NULL,NULL,100,1,1)",
    );
String _userSql(String values) =>
    "INSERT INTO users (email,full_name,role,status,balance_cop,created_at,updated_at) "
    "VALUES ('bad@example.com','Bad',$values,1,1)";
String _identifierSql(String normalized, String kind) =>
    "INSERT INTO login_identifiers VALUES ('$normalized',2,'$kind')";
String _addressSql(String line, String label) =>
    "INSERT INTO addresses (user_id,line1,city,label,is_primary) "
    "VALUES (2,'$line','Medellin','$label',1)";
String _transferSql({
  required int amount,
  String status = 'completed',
  int destination = 3,
}) =>
    "INSERT INTO transfers VALUES ('transfer-$amount-$status-$destination',2,"
    "$destination,$amount,'$status',NULL,1,'Origin','Destination')";
