import 'dart:io';

import 'package:core/security/credential_hasher.dart';
import 'package:core/errors/error.dart';
import 'package:core/errors/result.dart';
import 'package:core/security/activation_code_generator.dart';
import 'package:drift/native.dart';
import 'package:feature_auth/data/datasources/auth_local_datasource.dart';
import 'package:feature_auth/data/repository/auth_repository_impl.dart';
import 'package:feature_auth/domain/usecases/auth_usecases.dart';
import 'package:cotrafa_database/cotrafa_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late CotrafaDatabase database;
  late AuthRepositoryImpl repository;

  setUp(() async {
    final hasher = CredentialHasher(
      memoryKiB: 64,
      iterations: 1,
      saltFactory: () => List<int>.filled(16, 7),
    );
    database = CotrafaDatabase.forTesting(
      NativeDatabase.memory(),
      hasher,
      seed: _demoSeed,
    );
    repository = AuthRepositoryImpl(
      AuthLocalDatasource(
        database,
        hasher,
        SecureActivationCodeGenerator(),
        _demoSeed,
      ),
    );
    await database.customStatement(
      "INSERT INTO users (id,email,full_name,role,status,password_hash,"
      "activation_code_hash,balance_cop,created_at,updated_at) VALUES "
      "(2,'Client@Example.com','Client','client','pendingActivation',"
      'NULL,NULL,0,1,1)',
    );
    await database.customStatement(
      "INSERT INTO login_identifiers VALUES ('client@example.com',2,'email')",
    );
  });
  tearDown(() => database.close());

  test('layered auth flow uses core results', () async {
    final issued = await IssueActivationCode(repository)(
      1,
      ' CLIENT@EXAMPLE.COM ',
    );
    expect(issued.valueOrNull, matches(RegExp(r'^\d{6}$')));
    final activated = await ActivateClient(repository)(
      'client@example.com',
      issued.valueOrNull!,
      ' Alice ',
      'secret',
    );
    expect(activated.valueOrNull?.userId, 2);
    final loggedIn = await Login(repository)('alice', 'secret');
    expect(loggedIn.valueOrNull?.role, 'client');
    expect((await RestoreSession(repository)()).valueOrNull?.userId, 2);
    expect(await Logout(repository)(), const Success<void>(null));
    expect((await RestoreSession(repository)()).valueOrNull, isNull);
  });

  test('demo login delegates fixed credentials to persistence', () async {
    final result = await LoginDemoAdmin(repository)();

    expect(result.valueOrNull?.userId, _demoSeed.userId);
    expect(result.valueOrNull?.role, 'admin');
  });

  test('duplicate normalized username rolls activation back', () async {
    final code = (await IssueActivationCode(repository)(
      1,
      'client@example.com',
    )).valueOrNull!;
    final result = await ActivateClient(repository)(
      'client@example.com',
      code,
      ' ADMIN@COTRAFA.LOCAL ',
      'secret',
    );
    expect(result.errorOrNull, isA<DuplicateFailure>());
    final row = await database
        .customSelect(
          'SELECT status,activation_code_hash FROM users WHERE id=2',
        )
        .getSingle();
    expect(row.read<String>('status'), 'pendingActivation');
    expect(row.readNullable<String>('activation_code_hash'), isNotNull);

    final root = <Directory>[
      Directory('packages/features/auth/lib'),
      Directory('../../packages/features/auth/lib'),
      Directory('lib'),
    ].firstWhere((directory) => directory.existsSync());
    final repositorySource = File(
      '${root.path}/data/repository/auth_repository_impl.dart',
    ).readAsStringSync();
    final useCaseSource = File(
      '${root.path}/domain/usecases/auth_usecases.dart',
    ).readAsStringSync();
    expect(repositorySource, isNot(contains('cotrafa_database.dart')));
    expect(useCaseSource, isNot(contains('/data/')));
  });
}

const _demoSeed = CotrafaDatabaseSeed.demo();
