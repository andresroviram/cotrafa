import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('architecture boundary policy', () {
    test('allows persistence imports in a local datasource', () {
      final BoundaryScanReport report =
          scanArchitectureSources(<ArchitectureSource>[
            const ArchitectureSource(
              path: 'src/auth/data/datasources/auth_local_datasource.dart',
              content:
                  "import 'package:drift/drift.dart';\n"
                  "import 'package:features/src/database/"
                  "cootrafa_database.dart';",
            ),
          ]);

      expect(report.violations, isEmpty);
      expect(report.activeExceptions, isEmpty);
    });

    test('rejects reverse application and presentation data imports', () {
      final BoundaryScanReport report =
          scanArchitectureSources(<ArchitectureSource>[
            const ArchitectureSource(
              path: 'src/auth/domain/usecases/login.dart',
              content: "import 'package:cootrafa_app/app.dart';",
            ),
            const ArchitectureSource(
              path: 'src/user/presentation/users/user_list.dart',
              content:
                  "import '../../data/repository/user_repository_impl.dart';\n"
                  "import 'package:drift/drift.dart';",
            ),
            const ArchitectureSource(
              path: 'src/shared/application_adapter.dart',
              content:
                  "import '../../../../apps/cootrafa-app/lib/app.dart';\n"
                  "import 'package:features/src/database/"
                  "cootrafa_database.dart';",
            ),
          ]);

      expect(
        report.violations.map((BoundaryViolation item) => item.rule),
        <BoundaryRule>[
          BoundaryRule.featureDoesNotImportApp,
          BoundaryRule.layerDoesNotImportDataImplementation,
          BoundaryRule.layerDoesNotImportPersistence,
          BoundaryRule.persistenceImportsStayInDataSources,
          BoundaryRule.featureDoesNotImportApp,
          BoundaryRule.persistenceImportsStayInDataSources,
        ],
      );
      expect(report.violations.first.line, 1);
    });

    test('temporary paths are harmless when their debt is absent', () {
      final BoundaryScanReport report =
          scanArchitectureSources(<ArchitectureSource>[
            const ArchitectureSource(
              path: 'src/auth/auth_service.dart',
              content: "import 'package:equatable/equatable.dart';",
            ),
          ]);

      expect(report.violations, isEmpty);
      expect(report.activeExceptions, isEmpty);
    });

    test('final architecture markers reject active characterization debt', () {
      final Directory featureLib = _temporaryFeatureTree();
      addTearDown(() => featureLib.deleteSync(recursive: true));

      final BoundaryScanReport report = scanArchitectureTree(featureLib);

      expect(
        report.violations.map((BoundaryViolation item) => item.rule.name),
        contains('finalArchitectureHasActiveExceptions'),
        reason: report.describeViolations(),
      );
      expect(report.activeExceptions, <String>{'src/auth/auth_service.dart'});
    });

    test('one final marker preserves transitional characterization debt', () {
      final Directory featureLib = _temporaryFeatureTree(hasRoutes: false);
      addTearDown(() => featureLib.deleteSync(recursive: true));

      final BoundaryScanReport report = scanArchitectureTree(featureLib);

      expect(report.violations, isEmpty, reason: report.describeViolations());
      expect(report.activeExceptions, <String>{'src/auth/auth_service.dart'});
    });

    test('final architecture markers pass after debt removal', () {
      final Directory featureLib = _temporaryFeatureTree(hasDebt: false);
      addTearDown(() => featureLib.deleteSync(recursive: true));

      final BoundaryScanReport report = scanArchitectureTree(featureLib);

      expect(report.violations, isEmpty, reason: report.describeViolations());
      expect(report.activeExceptions, isEmpty);
    });

    test(
      'scans the live feature tree with only known characterization debt',
      () {
        final Directory featureLib = findFeatureLib();
        final BoundaryScanReport report = scanArchitectureTree(featureLib);

        expect(report.violations, isEmpty, reason: report.describeViolations());
        expect(
          report.activeExceptions.difference(_temporaryPersistenceExceptions),
          isEmpty,
          reason:
              'No source outside the four characterization services may '
              'be exempt.',
        );
      },
    );
  });
}

const Set<String> _temporaryPersistenceExceptions = <String>{
  'src/auth/auth_service.dart',
  'src/transfer/transfer_service.dart',
  'src/user/address/address_service.dart',
  'src/user/user_service.dart',
};

enum BoundaryRule {
  featureDoesNotImportApp,
  finalArchitectureHasActiveExceptions,
  layerDoesNotImportDataImplementation,
  layerDoesNotImportPersistence,
  persistenceImportsStayInDataSources,
}

class ArchitectureSource {
  const ArchitectureSource({required this.path, required this.content});

  final String path;
  final String content;
}

class BoundaryViolation {
  const BoundaryViolation({
    required this.rule,
    required this.path,
    required this.line,
    required this.importUri,
  });

  final BoundaryRule rule;
  final String path;
  final int line;
  final String importUri;

  @override
  String toString() => '$path:$line: ${rule.name}: $importUri';
}

class BoundaryScanReport {
  const BoundaryScanReport({
    required this.violations,
    required this.activeExceptions,
  });

  final List<BoundaryViolation> violations;
  final Set<String> activeExceptions;

  String describeViolations() {
    if (violations.isEmpty) {
      return 'No architecture boundary violations.';
    }

    return 'Architecture boundary violations:\n${violations.join('\n')}';
  }
}

BoundaryScanReport scanArchitectureTree(Directory featureLib) {
  final List<File> dartFiles =
      featureLib
          .listSync(recursive: true)
          .whereType<File>()
          .where((File file) => file.path.endsWith('.dart'))
          .toList()
        ..sort((File left, File right) => left.path.compareTo(right.path));
  final List<ArchitectureSource> sources = dartFiles
      .map(
        (File file) => ArchitectureSource(
          path: _relativePath(featureLib, file),
          content: file.readAsStringSync(),
        ),
      )
      .toList();

  final BoundaryScanReport report = scanArchitectureSources(sources);
  final bool hasFinalMarkers =
      File('${featureLib.path}/injectable.dart').existsSync() &&
      File('${featureLib.path}/routes.dart').existsSync();
  if (!hasFinalMarkers || report.activeExceptions.isEmpty) {
    return report;
  }

  return BoundaryScanReport(
    violations: <BoundaryViolation>[
      ...report.violations,
      for (final String path in report.activeExceptions)
        BoundaryViolation(
          rule: BoundaryRule.finalArchitectureHasActiveExceptions,
          path: path,
          line: 1,
          importUri: 'active temporary persistence exception',
        ),
    ],
    activeExceptions: report.activeExceptions,
  );
}

BoundaryScanReport scanArchitectureSources(List<ArchitectureSource> sources) {
  final List<BoundaryViolation> violations = <BoundaryViolation>[];
  final Set<String> activeExceptions = <String>{};
  final RegExp directive = RegExp(
    r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
  );

  for (final ArchitectureSource source in sources) {
    final String path = source.path.replaceAll('\\', '/');
    final List<String> lines = source.content.split('\n');
    for (int index = 0; index < lines.length; index++) {
      final RegExpMatch? match = directive.firstMatch(lines[index]);
      if (match == null) {
        continue;
      }
      final String importUri = match.group(1)!;
      final bool importsPersistence = _importsPersistence(importUri);

      if (_importsApplication(importUri)) {
        violations.add(
          _violation(
            BoundaryRule.featureDoesNotImportApp,
            path,
            index,
            importUri,
          ),
        );
      }
      if (_isDomainOrPresentation(path) && _importsData(importUri)) {
        violations.add(
          _violation(
            BoundaryRule.layerDoesNotImportDataImplementation,
            path,
            index,
            importUri,
          ),
        );
      }
      if (_isDomainOrPresentation(path) && importsPersistence) {
        violations.add(
          _violation(
            BoundaryRule.layerDoesNotImportPersistence,
            path,
            index,
            importUri,
          ),
        );
      }
      if (importsPersistence && !_isPersistenceOwner(path)) {
        if (_temporaryPersistenceExceptions.contains(path)) {
          activeExceptions.add(path);
        } else {
          violations.add(
            _violation(
              BoundaryRule.persistenceImportsStayInDataSources,
              path,
              index,
              importUri,
            ),
          );
        }
      }
    }
  }

  return BoundaryScanReport(
    violations: violations,
    activeExceptions: activeExceptions,
  );
}

BoundaryViolation _violation(
  BoundaryRule rule,
  String path,
  int zeroBasedLine,
  String importUri,
) => BoundaryViolation(
  rule: rule,
  path: path,
  line: zeroBasedLine + 1,
  importUri: importUri,
);

bool _importsApplication(String importUri) =>
    importUri.startsWith('package:cootrafa_app/') ||
    importUri.contains('apps/cootrafa-app/') ||
    importUri.contains('apps/cootrafa_app/');

bool _importsPersistence(String importUri) =>
    importUri.startsWith('package:drift/') ||
    importUri.endsWith('/cootrafa_database.dart') ||
    importUri == 'cootrafa_database.dart';

bool _importsData(String importUri) =>
    importUri.contains('/data/') ||
    importUri.startsWith('data/') ||
    importUri.startsWith('../data/') ||
    importUri.startsWith('../../data/') ||
    importUri.startsWith('../../../data/');

bool _isDomainOrPresentation(String path) =>
    path.contains('/domain/') || path.contains('/presentation/');

bool _isPersistenceOwner(String path) =>
    path.startsWith('src/database/') ||
    (path.contains('/data/datasources/') &&
        path.endsWith('_local_datasource.dart'));

String _relativePath(Directory root, File file) =>
    file.path.substring(root.path.length + 1).replaceAll('\\', '/');

Directory findFeatureLib() {
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

Directory _temporaryFeatureTree({
  bool hasInjectable = true,
  bool hasRoutes = true,
  bool hasDebt = true,
}) {
  final Directory root = Directory.systemTemp.createTempSync(
    'cootrafa_boundary_',
  );
  if (hasInjectable) {
    File('${root.path}/injectable.dart').createSync();
  }
  if (hasRoutes) {
    File('${root.path}/routes.dart').createSync();
  }
  File('${root.path}/src/auth/auth_service.dart')
    ..createSync(recursive: true)
    ..writeAsStringSync(
      hasDebt
          ? "import 'package:drift/drift.dart';"
          : "import 'package:equatable/equatable.dart';",
    );
  return root;
}
