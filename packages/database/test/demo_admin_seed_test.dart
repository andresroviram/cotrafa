import 'dart:io';

import 'package:cootrafa_database/cootrafa_database.dart';
import 'package:core/security/credential_hasher.dart';
import 'package:drift/drift.dart' show QueryRow;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('database owns the canonical demo administrator seed', () {
    const seed = CootrafaDatabaseSeed.demo();

    expect(seed.userId, 1);
    expect(seed.email, 'admin@cootrafa.local');
    expect(seed.fullName, 'Cootrafa Demo Admin');
    expect(seed.password, 'CootrafaDemo2026!');
  });

  test('database hashes the demo password and seeds idempotently', () async {
    final directory = await Directory.systemTemp.createTemp('demo-admin-');
    final file = File('${directory.path}/cootrafa.sqlite');
    final hasher = _fastHasher();
    const seed = CootrafaDatabaseSeed.demo();
    final first = CootrafaDatabase.forTesting(
      NativeDatabase(file),
      hasher,
      seed: seed,
    );
    await first.customSelect('SELECT 1').getSingle();
    final seeded = await _admin(first);
    final encoded = seeded.read<String>('password_hash');

    expect(seeded.read<int>('id'), seed.userId);
    expect(seeded.read<String>('email'), seed.email);
    expect(seeded.read<String>('full_name'), seed.fullName);
    expect(encoded, isNot(seed.password));
    expect(await hasher.verify(seed.password, encoded), isTrue);
    expect(await hasher.verify('wrong-password', encoded), isFalse);
    await first.close();

    final reopened = CootrafaDatabase.forTesting(
      NativeDatabase(file),
      hasher,
      seed: seed,
    );
    final rows = await reopened
        .customSelect('SELECT password_hash FROM users WHERE id = 1')
        .get();
    expect(rows, hasLength(1));
    expect(rows.single.read<String>('password_hash'), encoded);
    final identifier = await reopened
        .customSelect(
          'SELECT normalized FROM login_identifiers WHERE user_id = 1',
        )
        .getSingle();
    expect(identifier.read<String>('normalized'), seed.email);
    await reopened.close();
    await directory.delete(recursive: true);
  });
}

CredentialHasher _fastHasher() => CredentialHasher(
  memoryKiB: 64,
  iterations: 1,
  saltFactory: () => List<int>.filled(16, 7),
);

Future<QueryRow> _admin(CootrafaDatabase database) => database
    .customSelect(
      'SELECT id,email,full_name,password_hash FROM users WHERE id = 1',
    )
    .getSingle();
