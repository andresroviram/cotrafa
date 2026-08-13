import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('database package owns the Drift engine and tables', () {
    final workspace = _workspaceRoot();
    final database = Directory('${workspace.path}/packages/database');
    final appDatabase = Directory(
      '${workspace.path}/apps/cootrafa-app/lib/config/database',
    );

    expect(File('${database.path}/pubspec.yaml').existsSync(), isTrue);
    expect(
      File('${database.path}/lib/cootrafa_database.dart').existsSync(),
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

    for (final datasource in <String, String>{
      'auth': 'auth_local_datasource.dart',
      'user': 'user_local_datasource.dart',
      'user/address': 'address_local_datasource.dart',
      'transfer': 'transfer_local_datasource.dart',
    }.entries) {
      expect(
        File(
          '${workspace.path}/packages/features/${datasource.key.split('/').first}'
          '/lib/data/datasources/${datasource.value}',
        ).existsSync(),
        isTrue,
      );
    }
    expect(
      File(
        '${workspace.path}/packages/features/auth/lib/di/auth_module.dart',
      ).existsSync(),
      isFalse,
    );
    expect(
      File(
        '${workspace.path}/apps/cootrafa-app/lib/config/injectable/auth_module.dart',
      ).existsSync(),
      isFalse,
    );

    final authDatasource = File(
      '${workspace.path}/packages/features/auth/lib/data/datasources/'
      'auth_local_datasource.dart',
    ).readAsStringSync();
    expect(
      authDatasource,
      contains('abstract interface class IAuthLocalDatasource'),
    );
    expect(
      authDatasource,
      contains('@LazySingleton(as: IAuthLocalDatasource)'),
    );
    expect(authDatasource, isNot(contains('@module')));
    expect(authDatasource, contains('@Singleton(as: CootrafaDatabaseSeed)'));
    expect(
      authDatasource,
      contains('class DemoAdminDatabaseSeed extends CootrafaDatabaseSeed'),
    );
    expect(
      File(
        '${workspace.path}/packages/features/auth/lib/data/datasources/'
        'i_auth_local_datasource.dart',
      ).existsSync(),
      isFalse,
    );
  });
}

Directory _workspaceRoot() =>
    <Directory>[Directory.current, Directory.current.parent.parent].firstWhere(
      (root) => Directory('${root.path}/packages/database').existsSync(),
    );
