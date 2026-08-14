import 'dart:io';

import 'package:cotrafa_database/cotrafa_database.dart';
import 'package:core/errors/error.dart';
import 'package:core/errors/result.dart';
import 'package:core/security/credential_hasher.dart';
import 'package:drift/native.dart';
import 'package:feature_user/data/datasources/user_local_datasource.dart';
import 'package:feature_user/data/repository/user_repository_impl.dart';
import 'package:feature_user/domain/entities/delete_outcome.dart';
import 'package:feature_user/domain/usecases/user_usecases.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late CotrafaDatabase database;
  late UserRepositoryImpl repository;

  setUp(() async {
    database = CotrafaDatabase.forTesting(
      NativeDatabase.memory(),
      CredentialHasher(
        memoryKiB: 64,
        iterations: 1,
        saltFactory: () => List<int>.filled(16, 7),
      ),
      seed: CotrafaDatabaseSeed.test,
    );
    repository = UserRepositoryImpl(
      UserLocalDatasource(database, CotrafaDatabaseSeed.test),
    );
    await database.customSelect('SELECT 1').getSingle();
  });

  tearDown(() => database.close());

  test('layered user flow exposes CRUD through Core Result', () async {
    final created = await CreateClient(repository)(
      1,
      email: ' CLIENT@EXAMPLE.COM ',
      initialBalanceCop: 150000,
    );
    final user = created.valueOrNull!;

    expect(user.email, 'client@example.com');
    expect(user.balanceCop, 150000);
    expect((await ListUsers(repository)(1)).valueOrNull, hasLength(2));
    expect(
      (await GetUser(repository)(1, user.id)).valueOrNull?.email,
      'client@example.com',
    );
    expect(
      (await EditUserProfile(repository)(
        1,
        user.id,
        fullName: 'Updated Client',
      )).valueOrNull?.fullName,
      'Updated Client',
    );
    expect(
      await DeleteUser(repository)(1, user.id),
      const Success<DeleteOutcome>(DeleteOutcome.deleted),
    );
  });

  test('repository maps user errors without leaking persistence', () async {
    final invalid = await CreateClient(repository)(
      1,
      email: 'client@example.com',
      initialBalanceCop: -1,
    );
    final missing = await GetUser(repository)(1, 999);
    final unauthorized = await ListUsers(repository)(999);

    expect(invalid.errorOrNull, isA<ValidationFailure>());
    expect(missing.errorOrNull, isA<NotFoundFailure>());
    expect(unauthorized.errorOrNull, isA<UnauthorizedFailure>());

    final root = <Directory>[
      Directory('packages/features/user/lib'),
      Directory('../../packages/features/user/lib'),
      Directory('lib'),
    ].firstWhere((directory) => directory.existsSync());
    final repositorySource = File(
      '${root.path}/data/repository/user_repository_impl.dart',
    ).readAsStringSync();
    final useCaseSource = File(
      '${root.path}/domain/usecases/user_usecases.dart',
    ).readAsStringSync();

    expect(repositorySource, isNot(contains('cotrafa_database.dart')));
    expect(useCaseSource, isNot(contains('/data/')));
  });
}
