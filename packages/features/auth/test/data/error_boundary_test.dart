import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Feature Auth delegates exception policy to Core Result', () {
    final root = _packageRoot();
    final sources = Directory('${root.path}/lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .map((file) => file.readAsStringSync())
        .join('\n');
    final datasource = File(
      '${root.path}/lib/data/datasources/auth_local_datasource.dart',
    ).readAsStringSync();

    expect(
      File('${root.path}/lib/data/errors/auth_exception.dart').existsSync(),
      isFalse,
    );
    expect(sources, isNot(contains('enum AuthException')));
    expect(datasource, contains("import 'package:core/errors/error.dart';"));
  });

  test('Feature Auth has no parallel Result implementation', () {
    final root = _packageRoot();
    final sources = Directory('${root.path}/lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .map((file) => file.readAsStringSync())
        .join('\n');

    expect(
      File('${root.path}/lib/data/datasources/auth_result.dart').existsSync(),
      isFalse,
    );
    expect(sources, isNot(contains('class AuthResult')));
    expect(sources, isNot(contains('sealed class AuthResult')));
  });
}

Directory _packageRoot() => <Directory>[
  Directory.current,
  Directory('${Directory.current.path}/packages/features/auth'),
].firstWhere((root) => File('${root.path}/pubspec.yaml').existsSync());
