import 'package:drift/drift.dart' show QueryRow;
import 'package:drift/native.dart';
import 'package:features/src/auth/auth_service.dart';
import 'package:features/src/database/cootrafa_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late CootrafaDatabase database;
  late CredentialHasher hasher;
  late QueueCodeGenerator codes;
  late AuthService auth;

  setUp(() async {
    hasher = CredentialHasher(
      memoryKiB: 64,
      iterations: 1,
      saltFactory: () => List<int>.filled(16, 7),
    );
    database = CootrafaDatabase(
      NativeDatabase.memory(),
      credentialHasher: hasher,
    );
    codes = QueueCodeGenerator(<String>['FIRST1', 'SECOND2', 'THIRD3']);
    auth = AuthService(database, hasher, codes);
    await database.customSelect('SELECT 1').getSingle();
  });

  tearDown(() => database.close());

  test(
    'admin replaces a pending client code without persisting plaintext',
    () async {
      await _insertClient(database, 2, 'Client@Example.com');
      final denied = await auth.issueActivationCode(2, 'client@example.com');
      expect(denied.error, AuthError.unauthorized);
      await database.customStatement(
        "UPDATE users SET status='inactive' WHERE id=1",
      );
      expect(
        (await auth.issueActivationCode(1, 'client@example.com')).error,
        AuthError.unauthorized,
      );
      await database.customStatement(
        "UPDATE users SET status='active' WHERE id=1",
      );
      final first = await auth.issueActivationCode(
        DemoAdmin.userId,
        ' CLIENT@EXAMPLE.COM ',
      );
      expect(first.value, 'FIRST1');
      var row = await _client(database);
      expect(
        row.read<String>('activation_code_hash'),
        isNot(contains('FIRST1')),
      );

      final second = await auth.issueActivationCode(
        DemoAdmin.userId,
        'client@example.com',
      );
      expect(second.value, 'SECOND2');
      expect(
        (await auth.activate(
          'client@example.com',
          'FIRST1',
          'alice',
          'secret',
        )).error,
        AuthError.invalidCredentials,
      );
      expect(
        (await auth.activate(
          'client@example.com',
          'SECOND2',
          'alice',
          'secret',
        )).value?.userId,
        2,
      );
      expect(
        (await auth.issueActivationCode(
          DemoAdmin.userId,
          'client@example.com',
        )).error,
        AuthError.clientNotPending,
      );
    },
  );

  test(
    'activation reserves the global namespace and rolls back collisions',
    () async {
      await _insertClient(database, 2, 'client@example.com');
      final code = (await auth.issueActivationCode(
        DemoAdmin.userId,
        'client@example.com',
      )).value!;
      final collision = await auth.activate(
        'CLIENT@example.com',
        code,
        ' ADMIN@COOTRAFA.LOCAL ',
        'secret',
      );
      expect(collision.error, AuthError.identifierTaken);
      var row = await _client(database);
      expect(row.read<String>('status'), 'pendingActivation');
      expect(row.read<String>('activation_code_hash'), isNotNull);

      final activated = await auth.activate(
        'client@example.com',
        code,
        ' Alice ',
        'secret',
      );
      expect(activated.value, const AuthIdentity(userId: 2, role: 'client'));
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
        DemoAdmin.userId,
        'client@example.com',
      )).value!;
      await auth.activate('client@example.com', code, 'Alice', 'secret');

      expect(
        (await auth.login('CLIENT@EXAMPLE.COM', 'secret')).value?.userId,
        2,
      );
      await auth.logout();
      expect((await auth.login(' alice ', 'secret')).value?.userId, 2);
      expect((await auth.restore()).value?.role, 'client');
      expect(
        (await auth.login('alice', 'wrong')).error,
        AuthError.invalidCredentials,
      );
      expect(
        (await auth.login(DemoAdmin.email, DemoAdmin.password)).value,
        const AuthIdentity(userId: DemoAdmin.userId, role: 'admin'),
      );

      await database.customStatement(
        "UPDATE users SET status='inactive' WHERE id=1",
      );
      expect((await auth.restore()).value, isNull);
      expect(await database.currentSessionUserId(), isNull);
      expect(
        (await auth.login(DemoAdmin.email, DemoAdmin.password)).error,
        AuthError.invalidCredentials,
      );
      await database.customStatement('PRAGMA foreign_keys=OFF');
      await database.customStatement(
        'INSERT INTO local_session VALUES (1,999)',
      );
      expect((await auth.restore()).value, isNull);
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
