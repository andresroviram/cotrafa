import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps each Cootrafa feature in an independent workspace package', () {
    final workspace = _workspaceRoot();
    final workspaceManifest = File(
      '${workspace.path}/pubspec.yaml',
    ).readAsStringSync();
    final appManifest = File(
      '${workspace.path}/apps/cootrafa-app/pubspec.yaml',
    ).readAsStringSync();

    expect(
      File(
        '${workspace.path}/packages/features/cootrafa/pubspec.yaml',
      ).existsSync(),
      isFalse,
    );

    for (final feature in ['auth', 'user', 'transfer']) {
      final packageRoot = Directory(
        '${workspace.path}/packages/features/$feature',
      );
      final packageManifest = File('${packageRoot.path}/pubspec.yaml');

      expect(
        packageRoot.existsSync(),
        isTrue,
        reason: 'Missing feature package: $feature',
      );
      expect(packageManifest.existsSync(), isTrue);
      expect(
        packageManifest.readAsStringSync(),
        contains('name: feature_$feature'),
      );
      expect(workspaceManifest, contains('packages/features/$feature'));
      expect(appManifest, contains('feature_$feature:'));
      expect(
        File('${packageRoot.path}/lib/injectable.dart').existsSync(),
        isTrue,
      );
      expect(File('${packageRoot.path}/lib/routes.dart').existsSync(), isTrue);
    }
  });
}

Directory _workspaceRoot() {
  if (File('apps/cootrafa-app/pubspec.yaml').existsSync()) {
    return Directory.current;
  }
  return Directory.current.parent.parent;
}
