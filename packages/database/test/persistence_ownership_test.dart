import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('database package owns persistence implementation and tests', () {
    final workspace = _workspaceRoot();
    final database = Directory('${workspace.path}/packages/database');
    final appDatabase = Directory(
      '${workspace.path}/apps/cootrafa-app/lib/config/database',
    );
    final appDatabaseTests = Directory(
      '${workspace.path}/apps/cootrafa-app/test/config/database',
    );

    expect(File('${database.path}/pubspec.yaml').existsSync(), isTrue);
    expect(
      File('${database.path}/lib/cootrafa_database.dart').existsSync(),
      isTrue,
    );
    expect(
      File('${database.path}/test/demo_admin_seed_test.dart').existsSync(),
      isTrue,
    );
    for (final table in <String>[
      'users',
      'login_identifiers',
      'addresses',
      'transfers',
      'local_session',
    ]) {
      expect(
        File('${database.path}/lib/tables/$table.dart').existsSync(),
        isTrue,
      );
    }

    expect(appDatabaseTests.existsSync(), isFalse);
    expect(
      File('${appDatabase.path}/database_module.dart').existsSync(),
      isFalse,
    );
    expect(Directory('${appDatabase.path}/adapters').existsSync(), isFalse);
    expect(Directory('${appDatabase.path}/tables').existsSync(), isFalse);
    expect(
      File('${appDatabase.path}/cootrafa_database.dart').existsSync(),
      isFalse,
    );
  });

  test('Auth owns its datasource but not database seed configuration', () {
    final workspace = _workspaceRoot();
    final authRoot = Directory('${workspace.path}/packages/features/auth');
    final authDatasource = File(
      '${authRoot.path}/lib/data/datasources/auth_local_datasource.dart',
    ).readAsStringSync();

    expect(
      authDatasource,
      contains('abstract interface class IAuthLocalDatasource'),
    );
    expect(
      authDatasource,
      contains('@LazySingleton(as: IAuthLocalDatasource)'),
    );
    expect(authDatasource, contains('loginDemoAdmin'));
    expect(authDatasource, isNot(contains('@module')));
    expect(authDatasource, isNot(contains('DemoAdminDatabaseSeed')));
    expect(
      authDatasource,
      isNot(contains('@Singleton(as: CootrafaDatabaseSeed)')),
    );
    expect(
      File(
        '${authRoot.path}/lib/domain/entities/demo_credentials.dart',
      ).existsSync(),
      isFalse,
    );
    expect(
      File('${authRoot.path}/lib/di/auth_module.dart').existsSync(),
      isFalse,
    );
  });
}

Directory _workspaceRoot() =>
    <Directory>[Directory.current, Directory.current.parent.parent].firstWhere(
      (root) => Directory('${root.path}/packages/database').existsSync(),
    );
