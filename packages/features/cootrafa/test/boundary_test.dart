import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('features never references the application package', () {
    final Directory featureLib = _findFeatureLib();
    final List<String> violations = <String>[];
    final List<File> dartFiles =
        featureLib
            .listSync(recursive: true)
            .whereType<File>()
            .where((File file) => file.path.endsWith('.dart'))
            .toList()
          ..sort((File left, File right) => left.path.compareTo(right.path));

    for (final File file in dartFiles) {
      final List<String> lines = file.readAsLinesSync();
      for (int index = 0; index < lines.length; index++) {
        final String line = lines[index];
        if (line.contains('package:cootrafa_app/') ||
            line.contains('apps/cootrafa-app/')) {
          violations.add('${file.path}:${index + 1}: $line');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Feature sources must not depend on the application:\n'
          '${violations.join('\n')}',
    );
  });
}

Directory _findFeatureLib() {
  final List<Directory> candidates = <Directory>[
    Directory('packages/features/cootrafa/lib'),
    Directory('lib'),
  ];

  return candidates.firstWhere(
    (Directory directory) => directory.existsSync(),
    orElse: () =>
        throw StateError('Unable to locate the features lib directory.'),
  );
}
