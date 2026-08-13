import 'package:core/errors/error.dart';
import 'package:drift/drift.dart' show QueryRow;
import 'package:drift/native.dart';
import 'package:feature_auth/data/datasources/auth_local_datasource.dart';
import 'package:core/security/activation_code_generator.dart';
import 'package:core/security/credential_hasher.dart';
import 'package:feature_auth/domain/entities/auth_identity.dart';
import 'package:cootrafa_database/cootrafa_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late CootrafaDatabase database;
  late CredentialHasher hasher;
  late QueueCodeGenerator codes;
  late AuthLocalDatasource auth;

  setUp(() async {
    hasher = CredentialHasher(
      memoryKiB: 64,
      iterations: 1,
      saltFactory: () => List<int>.filled(16, 7),
    );
    database = CootrafaDatabase.forTesting(
      NativeDatabase.memory(),
      hasher,
      seed: _demoSeed,
    );
    codes = QueueCodeGenerator(<String>['FIRST1', 'SECOND2', 'THIRD3']);
    auth = AuthLocalDatasource(database, hasher, codes, _demoSeed);
    await database.customSelect('SELECT 1').getSingle();
  });

  tearDown(() => database.close());

  test(
    'admin replaces a pending client code without persisting plaintext',
    () async {
      await _insertClient(database, 2, 'Client@Example.com');
      await expectLater(
        auth.issueActivationCode(2, 'client@example.com'),
        throwsA(isA<UnauthorizedException>()),
      );
      await database.customStatement(
        "UPDATE users SET status='inactive' WHERE id=1",
      );
      await expectLater(
        auth.issueActivationCode(1, 'client@example.com'),
        throwsA(isA<UnauthorizedException>()),
      );
      await database.customStatement(
        "UPDATE users SET status='active' WHERE id=1",
      );
      final first = await auth.issueActivationCode(
        _demoSeed.userId,
        ' CLIENT@EXAMPLE.COM ',
      );
      expect(first, 'FIRST1');
      var row = await _client(database);
      expect(
        row.read<String>('activation_code_hash'),
        isNot(contains('FIRST1')),
      );

      final second = await auth.issueActivationCode(
        _demoSeed.userId,
        'client@example.com',
      );
      expect(second, 'SECOND2');
      await expectLater(
        auth.activate('client@example.com', 'FIRST1', 'alice', 'secret'),
        throwsA(isA<AuthException>()),
      );
      expect(
        (await auth.activate(
          'client@example.com',
          'SECOND2',
          'alice',
          'secret',
        )).userId,
        2,
      );
      await expectLater(
        auth.issueActivationCode(_demoSeed.userId, 'client@example.com'),
        throwsA(isA<ValidationException>()),
      );
    },
  );

  test(
    'activation reserves the global namespace and rolls back collisions',
    () async {
      await _insertClient(database, 2, 'client@example.com');
      final code = (await auth.issueActivationCode(
        _demoSeed.userId,
        'client@example.com',
      ));
      await expectLater(
        auth.activate(
          'CLIENT@example.com',
          code,
          ' ADMIN@COOTRAFA.LOCAL ',
          'secret',
        ),
        throwsA(isA<DuplicateException>()),
      );
      var row = await _client(database);
      expect(row.read<String>('status'), 'pendingActivation');
      expect(row.read<String>('activation_code_hash'), isNotNull);

      final activated = await auth.activate(
        'client@example.com',
        code,
        ' Alice ',
        'secret',
      );
      expect(activated, const AuthIdentity(userId: 2, role: 'client'));
      row = await _client(database);
      expect(row.read<String>('status'), 'active');
      expect(row.readNullable<String>('activation_code_hash'), isNull);
      expect(row.read<String>('password_hash'), isNot(contains('secret')));
      expect(
        await database
            .customSelect(
              "SELECT normalized FROM login_identifiers WHERE kind='username'",
            )
            .map((row) => row.read<String>('normalized'))
            .getSingle(),
        'alice',
      );
    },
  );

  test(
    'login, restore, inactive clearing, demo admin, and logout use userId session',
    () async {
      await _insertClient(database, 2, 'client@example.com');
      final code = (await auth.issueActivationCode(
        _demoSeed.userId,
        'client@example.com',
      ));
      await auth.activate('client@example.com', code, 'Alice', 'secret');

      expect((await auth.login('CLIENT@EXAMPLE.COM', 'secret')).userId, 2);
      await auth.logout();
      expect((await auth.login(' alice ', 'secret')).userId, 2);
      expect((await auth.restore())?.role, 'client');
      await expectLater(
        auth.login('alice', 'wrong'),
        throwsA(isA<AuthException>()),
      );
      expect(
        await auth.loginDemoAdmin(),
        AuthIdentity(userId: _demoSeed.userId, role: 'admin'),
      );

      await database.customStatement(
        "UPDATE users SET status='inactive' WHERE id=1",
      );
      expect(await auth.restore(), isNull);
      expect(await database.currentSessionUserId(), isNull);
      await expectLater(auth.loginDemoAdmin(), throwsA(isA<AuthException>()));
      await database.customStatement('PRAGMA foreign_keys=OFF');
      await database.customStatement(
        'INSERT INTO local_session VALUES (1,999)',
      );
      expect(await auth.restore(), isNull);
      expect(await database.currentSessionUserId(), isNull);
      await auth.logout();
      expect(await database.currentSessionUserId(), isNull);
    },
  );
}

Future<void> _insertClient(
  CootrafaDatabase database,
  int id,
  String email,
) async {
  await database.customStatement(
    "INSERT INTO users VALUES ($id,'$email','Client','client',"
    "'pendingActivation',NULL,NULL,0,1,1)",
  );
  await database.customStatement(
    "INSERT INTO login_identifiers VALUES ('${email.trim().toLowerCase()}',$id,'email')",
  );
}

Future<QueryRow> _client(CootrafaDatabase database) =>
    database.customSelect('SELECT * FROM users WHERE id=2').getSingle();

final class QueueCodeGenerator implements ActivationCodeGenerator {
  QueueCodeGenerator(this.values);
  final List<String> values;
  @override
  String generate() => values.removeAt(0);
}

const _demoSeed = CootrafaDatabaseSeed.demo();
