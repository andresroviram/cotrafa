import 'dart:io';

import 'package:core/errors/error.dart';
import 'package:core/security/credential_hasher.dart';
import 'package:cotrafa_database/cotrafa_database.dart';
import 'package:drift/drift.dart' show QueryRow;
import 'package:drift/native.dart';
import 'package:feature_user/data/datasources/address_local_datasource.dart';
import 'package:feature_user/domain/entities/user_address.dart';
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
      expect(await addresses.list(2, 2), isEmpty);
      final own = await addresses.create(2, 2, _draft('Own'));
      expect(own.isPrimary, isTrue);
      expect(own.line2, 'Suite Own');
      expect(own.state, 'Antioquia');
      expect(own.postalCode, '050001');
      expect(own.country, 'Colombia');
      expect(await addresses.list(2, 2), hasLength(1));
      await expectLater(
        addresses.create(2, 3, _draft('Attack')),
        throwsA(isA<UnauthorizedException>()),
      );
      expect((await addresses.create(1, 3, _draft('Admin'))).isPrimary, isTrue);
      await database.customStatement(
        "UPDATE users SET status='inactive' WHERE id=2",
      );
      await expectLater(
        addresses.list(2, 2),
        throwsA(isA<UnauthorizedException>()),
      );
      await expectLater(
        addresses.list(1, 2),
        throwsA(isA<ValidationException>()),
      );
    },
  );

  test(
    'primary selection is explicit and rolls back on database failure',
    () async {
      final first = await addresses.create(2, 2, _draft('First'));
      final second = await addresses.create(2, 2, _draft('Second'));
      expect(first.isPrimary, isTrue);
      expect(second.isPrimary, isFalse);
      final edited = await addresses.update(2, 2, second.id, _draft('Edited'));
      expect(edited.label, 'Edited');
      expect(edited.isPrimary, isFalse);
      expect((await addresses.selectPrimary(2, 2, second.id)).id, second.id);
      await database.customStatement(
        'CREATE TRIGGER fail_primary BEFORE UPDATE OF is_primary ON addresses '
        "WHEN NEW.id=${first.id} AND NEW.is_primary=1 BEGIN SELECT RAISE(ABORT,'fail'); END",
      );
      await expectLater(
        addresses.selectPrimary(2, 2, first.id),
        throwsA(anything),
      );
      final rows = await addresses.list(2, 2);
      expect(rows.singleWhere((row) => row.isPrimary).id, second.id);
    },
  );

  test('delete promotes lowest ID, supports empty, and rolls back', () async {
    final first = await addresses.create(2, 2, _draft('First'));
    final second = await addresses.create(2, 2, _draft('Second'));
    final third = await addresses.create(2, 2, _draft('Third'));
    await addresses.selectPrimary(2, 2, second.id);
    await database.customStatement(
      'CREATE TRIGGER fail_promotion BEFORE UPDATE OF is_primary ON addresses '
      "WHEN NEW.id=${first.id} AND NEW.is_primary=1 BEGIN SELECT RAISE(ABORT,'fail'); END",
    );
    await expectLater(addresses.delete(2, 2, second.id), throwsA(anything));
    var rows = await addresses.list(2, 2);
    expect(rows, hasLength(3));
    expect(rows.singleWhere((row) => row.isPrimary).id, second.id);
    await database.customStatement('DROP TRIGGER fail_promotion');
    await addresses.delete(2, 2, third.id);
    await addresses.delete(2, 2, second.id);
    rows = await addresses.list(2, 2);
    expect(rows.single.isPrimary, isTrue);
    await addresses.delete(2, 2, first.id);
    expect(await addresses.list(2, 2), isEmpty);
  });

  test(
    'address changes never affect transfer creation or receipt snapshots',
    () async {
      await database.customStatement(
        "INSERT INTO transfers VALUES ('receipt',2,3,10,'completed',NULL,1,'Origin','Destination')",
      );
      final before = await _receipt(database);
      final address = await addresses.create(2, 2, _draft('Transferless'));
      await addresses.update(2, 2, address.id, _draft('Changed'));
      await addresses.delete(2, 2, address.id);
      final after = await _receipt(database);
      expect(after.read<int>('amount_cop'), before.read<int>('amount_cop'));
      expect(after.read<String>('origin_snapshot'), 'Origin');
      expect(after.read<String>('destination_snapshot'), 'Destination');
      expect(after.read<String>('status'), 'completed');
    },
  );

  test('migrates v1 addresses without data loss', () async {
    await database.close();
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
    final datasource = AddressLocalDatasource(migrated);
    final created = await datasource.create(1, 4, _draft('Migrated'));
    expect(created.country, 'Colombia');
    final rows = await datasource.list(1, 4);
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

AddressDraft _draft(String label) => AddressDraft(
  line1: 'Street $label',
  line2: 'Suite $label',
  city: 'Medellin',
  state: 'Antioquia',
  postalCode: '050001',
  country: 'Colombia',
  label: label,
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
