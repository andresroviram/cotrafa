import 'dart:io';

import 'package:core/security/credential_hasher.dart';
import 'package:drift/drift.dart' show QueryRow;
import 'package:drift/native.dart';
import 'package:cotrafa_database/cotrafa_database.dart';
import 'package:feature_user/data/datasources/address_local_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late CotrafaDatabase database;
  late AddressLocalDatasource addresses;
  setUp(() async {
    database = CotrafaDatabase.forTesting(
      NativeDatabase.memory(),
      CredentialHasher(
        memoryKiB: 64,
        iterations: 1,
        saltFactory: () => List<int>.filled(16, 7),
      ),
    );
    addresses = AddressLocalDatasource(database);
    await database.customSelect('SELECT 1').getSingle();
    await _activeUser(database, 2, 'client@example.com');
    await _activeUser(database, 3, 'other@example.com');
  });
  tearDown(() => database.close());
  test(
    'client owns addresses while admin can manage any active user',
    () async {
      expect((await addresses.list(2, 2)).value, isEmpty);
      final own = (await addresses.create(2, 2, _input('Own'))).value!;
      expect(own.isPrimary, isTrue);
      expect(own.line2, 'Suite Own');
      expect(own.state, 'Antioquia');
      expect(own.postalCode, '050001');
      expect(own.country, 'Colombia');
      expect((await addresses.list(2, 2)).value?.length, 1);
      expect(
        (await addresses.create(2, 3, _input('Attack'))).error,
        AddressError.unauthorized,
      );
      expect(
        (await addresses.create(1, 3, _input('Admin'))).value?.isPrimary,
        isTrue,
      );
      await database.customStatement(
        "UPDATE users SET status='inactive' WHERE id=2",
      );
      expect((await addresses.list(2, 2)).error, AddressError.unauthorized);
      expect((await addresses.list(1, 2)).error, AddressError.inactiveTarget);
    },
  );
  test(
    'primary selection is explicit and rolls back on database failure',
    () async {
      final first = (await addresses.create(2, 2, _input('First'))).value!;
      final second = (await addresses.create(2, 2, _input('Second'))).value!;
      expect(first.isPrimary, isTrue);
      expect(second.isPrimary, isFalse);
      final edited = (await addresses.update(
        2,
        2,
        second.id,
        _input('Edited'),
      )).value!;
      expect(edited.label, 'Edited');
      expect(edited.isPrimary, isFalse);
      expect(
        (await addresses.selectPrimary(2, 2, second.id)).value?.id,
        second.id,
      );
      await database.customStatement(
        'CREATE TRIGGER fail_primary BEFORE UPDATE OF is_primary ON addresses '
        "WHEN NEW.id=${first.id} AND NEW.is_primary=1 BEGIN SELECT RAISE(ABORT,'fail'); END",
      );
      expect(
        (await addresses.selectPrimary(2, 2, first.id)).error,
        AddressError.storageFailure,
      );
      final rows = (await addresses.list(2, 2)).value!;
      expect(rows.singleWhere((row) => row.isPrimary).id, second.id);
    },
  );
  test('delete promotes lowest ID, supports empty, and rolls back', () async {
    final first = (await addresses.create(2, 2, _input('First'))).value!;
    final second = (await addresses.create(2, 2, _input('Second'))).value!;
    final third = (await addresses.create(2, 2, _input('Third'))).value!;
    await addresses.selectPrimary(2, 2, second.id);
    await database.customStatement(
      'CREATE TRIGGER fail_promotion BEFORE UPDATE OF is_primary ON addresses '
      "WHEN NEW.id=${first.id} AND NEW.is_primary=1 BEGIN SELECT RAISE(ABORT,'fail'); END",
    );
    expect(
      (await addresses.delete(2, 2, second.id)).error,
      AddressError.storageFailure,
    );
    var rows = (await addresses.list(2, 2)).value!;
    expect(rows.length, 3);
    expect(rows.singleWhere((row) => row.isPrimary).id, second.id);
    await database.customStatement('DROP TRIGGER fail_promotion');
    expect((await addresses.delete(2, 2, third.id)).value, isTrue);
    await addresses.delete(2, 2, second.id);
    rows = (await addresses.list(2, 2)).value!;
    expect(rows.single.isPrimary, isTrue);
    await addresses.delete(2, 2, first.id);
    expect((await addresses.list(2, 2)).value, isEmpty);
  });
  test(
    'address changes never affect transfer creation or receipt snapshots',
    () async {
      await database.customStatement(
        "INSERT INTO transfers VALUES ('receipt',2,3,10,'completed',NULL,1,'Origin','Destination')",
      );
      final before = await _receipt(database);
      final address = (await addresses.create(
        2,
        2,
        _input('Transferless'),
      )).value!;
      await addresses.update(2, 2, address.id, _input('Changed'));
      await addresses.delete(2, 2, address.id);
      final after = await _receipt(database);
      expect(after.read<int>('amount_cop'), before.read<int>('amount_cop'));
      expect(after.read<String>('origin_snapshot'), 'Origin');
      expect(after.read<String>('destination_snapshot'), 'Destination');
      expect(after.read<String>('status'), 'completed');
    },
  );
  test('migrates v1 addresses without data loss', () async {
    final directory = await Directory.systemTemp.createTemp('cotrafa-v1-');
    final file = File('${directory.path}/legacy.sqlite');
    final legacy = CotrafaDatabase.forTesting(
      NativeDatabase(file),
      _fastHasher(),
    );
    await legacy.customSelect('SELECT 1').getSingle();
    await _activeUser(legacy, 4, 'legacy@example.com');
    await legacy.customStatement(
      "INSERT INTO addresses (user_id,line1,city,label,is_primary) "
      "VALUES (4,'Legacy','Cali','Home',1)",
    );
    for (final column in ['country', 'postal_code', 'state', 'line2']) {
      await legacy.customStatement('ALTER TABLE addresses DROP COLUMN $column');
    }
    for (final column in ['phone', 'birth_date', 'last_name', 'first_name']) {
      await legacy.customStatement('ALTER TABLE users DROP COLUMN $column');
    }
    await legacy.customStatement('PRAGMA user_version = 1');
    await legacy.close();
    final migrated = CotrafaDatabase.forTesting(
      NativeDatabase(file),
      _fastHasher(),
    );
    final service = AddressLocalDatasource(migrated);
    final created = await service.create(1, 4, _input('Migrated'));
    expect(created.value?.country, 'Colombia');
    final rows = (await service.list(1, 4)).value!;
    expect(
      rows.map((row) => row.line1),
      containsAll(['Legacy', 'Street Migrated']),
    );
    expect(migrated.schemaVersion, 3);
    final userColumns = await migrated
        .customSelect('PRAGMA table_info(users)')
        .get();
    expect(
      userColumns.map((row) => row.read<String>('name')),
      containsAll(['first_name', 'last_name', 'birth_date', 'phone']),
    );
    await migrated.close();
    await directory.delete(recursive: true);
  });
}

AddressInput _input(String label) => AddressInput(
  'Street $label',
  'Suite $label',
  'Medellin',
  'Antioquia',
  '050001',
  'Colombia',
  label,
);
CredentialHasher _fastHasher() => CredentialHasher(
  memoryKiB: 64,
  iterations: 1,
  saltFactory: () => List<int>.filled(16, 7),
);
Future<void> _activeUser(CotrafaDatabase database, int id, String email) async {
  await database.customStatement(
    "INSERT INTO users (id,email,full_name,role,status,password_hash,"
    "activation_code_hash,balance_cop,created_at,updated_at) VALUES "
    "($id,'$email','Client','client','active',NULL,NULL,100,1,1)",
  );
  await database.customStatement(
    "INSERT INTO login_identifiers VALUES ('$email',$id,'email')",
  );
}

Future<QueryRow> _receipt(CotrafaDatabase database) => database
    .customSelect("SELECT * FROM transfers WHERE id='receipt'")
    .getSingle();
