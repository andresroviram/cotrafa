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
      isTrue,
    );
    expect(Directory('${appDatabase.path}/tables').existsSync(), isFalse);
    expect(
      File('${appDatabase.path}/cootrafa_database.dart').existsSync(),
      isFalse,
    );
  });
}

Directory _workspaceRoot() =>
    <Directory>[Directory.current, Directory.current.parent.parent].firstWhere(
      (root) => Directory('${root.path}/packages/database').existsSync(),
    );
