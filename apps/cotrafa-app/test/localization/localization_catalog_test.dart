import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final workspace = _workspaceRoot();
  final spanish = _flatten(_catalog(workspace, 'es'));
  final english = _flatten(_catalog(workspace, 'en'));

  test('English and Spanish catalogs have the same non-empty keys', () {
    expect(english.keys.toSet(), spanish.keys.toSet());
    expect(spanish.values, everyElement(isNotEmpty));
    expect(english.values, everyElement(isNotEmpty));
  });

  test('every localization key used by the application exists', () {
    final usedKeys = <String>{};
    final keyPattern = RegExp(
      r'''['"]((?:app_title|switch_to_dark|switch_to_light|(?:common|nav|dashboard|language|performance_toggle|auth|user|address|transfer)\.[a-z0-9_.]+))['"]''',
    );
    for (final directory in _sourceDirectories(workspace)) {
      for (final entity in directory.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final source = entity.readAsStringSync();
        usedKeys.addAll(
          keyPattern.allMatches(source).map((match) => match.group(1)!),
        );
      }
    }

    expect(
      usedKeys.difference(spanish.keys.toSet()),
      isEmpty,
      reason: 'Every referenced key must exist in both catalogs.',
    );
  });

  test('presentation formatting has no fixed Spanish locale', () {
    for (final directory in _sourceDirectories(workspace)) {
      for (final entity in directory.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.path.endsWith('localized_formatters.dart')) continue;
        expect(
          entity.readAsStringSync(),
          isNot(contains("'es_CO'")),
          reason: '${entity.path} must follow the active locale.',
        );
      }
    }
  });
}

Map<String, dynamic> _catalog(Directory workspace, String languageCode) =>
    jsonDecode(
          File(
            '${workspace.path}/apps/cotrafa-app/assets/translations/'
            '$languageCode.json',
          ).readAsStringSync(),
        )
        as Map<String, dynamic>;

Map<String, String> _flatten(
  Map<String, dynamic> source, [
  String prefix = '',
]) {
  final result = <String, String>{};
  for (final entry in source.entries) {
    final key = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
    final value = entry.value;
    if (value is Map<String, dynamic>) {
      result.addAll(_flatten(value, key));
    } else {
      result[key] = value as String;
    }
  }
  return result;
}

List<Directory> _sourceDirectories(Directory workspace) => [
  Directory('${workspace.path}/apps/cotrafa-app/lib'),
  Directory('${workspace.path}/packages/components/lib'),
  Directory('${workspace.path}/packages/features/auth/lib/presentation'),
  Directory('${workspace.path}/packages/features/user/lib/presentation'),
  Directory('${workspace.path}/packages/features/transfer/lib/presentation'),
];

Directory _workspaceRoot() {
  var directory = Directory.current.absolute;
  while (!File('${directory.path}/pubspec.yaml').existsSync() ||
      !Directory('${directory.path}/apps/cotrafa-app').existsSync()) {
    final parent = directory.parent;
    if (parent.path == directory.path) {
      throw StateError('Cotrafa workspace not found.');
    }
    directory = parent;
  }
  return directory;
}
