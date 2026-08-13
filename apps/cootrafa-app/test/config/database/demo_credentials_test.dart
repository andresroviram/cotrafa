import 'dart:io';

import 'package:drift/drift.dart' show QueryRow;
import 'package:drift/native.dart';
import 'package:cootrafa_app/config/injectable/auth_module.dart';
import 'package:feature_auth/domain/entities/demo_credentials.dart';
import 'package:cootrafa_app/config/database/cootrafa_database.dart';
import 'package:core/security/credential_hasher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('declares direct Freezed dependencies and one credential source', () {
    final root = _packageRoot();
    final manifest = File('${root.path}/pubspec.yaml').readAsStringSync();
    final devStart = manifest.indexOf('dev_dependencies:');
    final runtimeDependencies = manifest.substring(0, devStart);
    final devDependencies = manifest.substring(devStart);
    expect(runtimeDependencies, contains('  freezed_annotation: ^3.1.0'));
    expect(devDependencies, contains('  freezed: ^3.2.5'));

    final canonical = File(
      '${root.path}/lib/domain/entities/demo_credentials.dart',
    );
    final productionSources = Directory('${root.path}/lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where(
          (file) =>
              file.path.endsWith('.dart') &&
              !file.path.endsWith('.g.dart') &&
              !file.path.endsWith('.freezed.dart'),
        );
    for (final source in productionSources.where(
      (file) => file.path != canonical.path,
    )) {
      final text = source.readAsStringSync();
      expect(text, isNot(contains('admin@cootrafa.local')));
      expect(text, isNot(contains('CootrafaDemo2026!')));
      expect(text, isNot(contains('package:cootrafa_app')));
    }
  });

  test('module binds the canonical const credentials by identity', () {
    const expected = DemoCredentials(
      identifier: 'admin@cootrafa.local',
      password: 'CootrafaDemo2026!',
    );
    final bound = _TestAuthModule().demoCredentials;

    expect(identical(bound, DemoAdmin.credentials), isTrue);
    expect(identical(bound, expected), isTrue);
    expect(DemoAdmin.email, bound.identifier);
    expect(DemoAdmin.password, bound.password);
    expect(DemoAdmin.userId, 1);
    expect(DemoAdmin.fullName, 'Cootrafa Demo Admin');
  });

  test('database seeds and reopens with the canonical credentials', () async {
    final directory = await Directory.systemTemp.createTemp('demo-admin-');
    final file = File('${directory.path}/cootrafa.sqlite');
    final hasher = _fastHasher();
    final first = CootrafaDatabase.forTesting(NativeDatabase(file), hasher);
    await first.customSelect('SELECT 1').getSingle();
    final seeded = await _admin(first);
    final encoded = seeded.read<String>('password_hash');

    expect(seeded.read<int>('id'), DemoAdmin.userId);
    expect(seeded.read<String>('email'), DemoAdmin.credentials.identifier);
    expect(seeded.read<String>('full_name'), DemoAdmin.fullName);
    expect(
      await hasher.verify(DemoAdmin.credentials.password, encoded),
      isTrue,
    );
    expect(await hasher.verify('wrong-password', encoded), isFalse);
    await first.close();

    final reopened = CootrafaDatabase.forTesting(NativeDatabase(file), hasher);
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
    expect(
      identifier.read<String>('normalized'),
      DemoAdmin.credentials.identifier,
    );
    await reopened.close();
    await directory.delete(recursive: true);
  });
}

final class _TestAuthModule extends AuthModule {}

Directory _packageRoot() =>
    <Directory>[
      Directory.current,
      Directory('${Directory.current.path}/packages/features/auth'),
      Directory('${Directory.current.path}/../../packages/features/auth'),
    ].firstWhere(
      (root) => File(
        '${root.path}/lib/domain/entities/demo_credentials.dart',
      ).existsSync(),
    );

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
