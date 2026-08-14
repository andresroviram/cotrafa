import 'dart:io';

import 'package:cotrafa_database/cotrafa_database.dart';
import 'package:core/security/credential_hasher.dart';
import 'package:drift/drift.dart' show QueryRow;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('database owns the canonical demo administrator seed', () {
    const seed = CotrafaDatabaseSeed.demo();

    expect(seed.userId, 1);
    expect(seed.email, 'admin@cotrafa.local');
    expect(seed.username, 'admin');
    expect(seed.fullName, 'Cotrafa Demo Admin');
    expect(seed.password, 'CotrafaDemo2026!');
  });

  test('database hashes the demo password and seeds idempotently', () async {
    final directory = await Directory.systemTemp.createTemp('demo-admin-');
    final file = File('${directory.path}/cotrafa.sqlite');
    final hasher = _fastHasher();
    const seed = CotrafaDatabaseSeed.demo();
    final first = CotrafaDatabase.forTesting(
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

    final reopened = CotrafaDatabase.forTesting(
      NativeDatabase(file),
      hasher,
      seed: seed,
    );
    final rows = await reopened
        .customSelect('SELECT password_hash FROM users WHERE id = 1')
        .get();
    expect(rows, hasLength(1));
    expect(rows.single.read<String>('password_hash'), encoded);
    final identifiers = await reopened
        .customSelect(
          'SELECT normalized,kind FROM login_identifiers '
          'WHERE user_id = 1 ORDER BY kind',
        )
        .get();
    expect(
      identifiers
          .map(
            (row) => (
              normalized: row.read<String>('normalized'),
              kind: row.read<String>('kind'),
            ),
          )
          .toList(),
      [
        (normalized: seed.email, kind: 'email'),
        (normalized: seed.username, kind: 'username'),
      ],
    );
    await reopened.close();
    await directory.delete(recursive: true);
  });
}

CredentialHasher _fastHasher() => CredentialHasher(
  memoryKiB: 64,
  iterations: 1,
  saltFactory: () => List<int>.filled(16, 7),
);

Future<QueryRow> _admin(CotrafaDatabase database) => database
    .customSelect(
      'SELECT id,email,full_name,password_hash FROM users WHERE id = 1',
    )
    .getSingle();
