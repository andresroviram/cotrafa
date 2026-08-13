import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('architecture boundary policy', () {
    test('allows persistence imports in a local datasource', () {
      final BoundaryScanReport report =
          scanArchitectureSources(<ArchitectureSource>[
            const ArchitectureSource(
              path: 'data/datasources/auth_local_datasource.dart',
              content:
                  "import 'package:drift/drift.dart';\n"
                  "import 'package:cootrafa_database/"
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
                  "import 'package:cootrafa_database/"
                  "cootrafa_database.dart';",
            ),
          ]);

      expect(
        report.violations.map((BoundaryViolation item) => item.rule),
        <BoundaryRule>[
          BoundaryRule.featureDoesNotImportApp,
          BoundaryRule.layerDoesNotImportDataImplementation,
          BoundaryRule.featureDoesNotImportDrift,
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

    test('canonical transition and final architectures are accepted', () {
      final BoundaryScanReport p2 = scanArchitectureSources(
        _sources(
          "database/lib/cootrafa_database.dart|import 'package:drift/drift.dart'; class CootrafaDatabase {}|database/lib/tables/users.dart|part of '../cootrafa_database.dart'; class Users {}|database/lib/injectable.dart|import 'package:injectable/injectable.dart';|app/lib/config/injectable/injectable_dependency.dart|import 'package:cootrafa_database/injectable.module.dart';",
        ),
      );
      final BoundaryScanReport pureBarrel = scanArchitectureSources(
        _sources(
          "auth.dart|export 'src/auth/domain/auth_port.dart';|src/auth/domain/auth_port.dart|abstract interface class AuthPort {}",
        ),
      );
      final violations = <BoundaryViolation>[
        ...scanArchitectureSources(
          _sources(
            "database/lib/cootrafa_database.dart|import 'package:drift/drift.dart';",
          ),
        ).violations,
        ...p2.violations,
        ...pureBarrel.violations,
        ...scanArchitectureSources(_finalArchitectureSources()).violations,
      ];
      expect(violations, isEmpty, reason: violations.join('\n'));
    });

    final List<String> rejectedFixtures = <String>[
      "feature app import|featureDoesNotImportApp|src/auth/domain/usecases/login.dart|import 'package:cootrafa_app/config/database/database_module.dart';",
      "feature Drift import|featureDoesNotImportDrift|src/user/domain/entities/profile.dart|import 'package:drift/drift.dart';",
      "app private feature import|appImportsPrivateFeature|app/lib/config/database/adapters/auth.dart|import '../../../../packages/features/auth/lib/src/port.dart';",
      "app DI private feature import|appImportsPrivateFeature|app/lib/config/injectable/injectable_dependency.dart|import 'package:feature_auth/src/injectable.dart';",
      "public barrel concrete leak|publicBarrelLeaksPersistence|auth.dart|export 'src/database/cootrafa_database.dart';",
      'final feature database|finalFeatureHasInfrastructure|src/database/cootrafa_database.dart|',
      'final feature security|finalFeatureHasInfrastructure|src/security/credential_hasher.dart|',
      'missing Freezed event|invalidFreezedEvent|src/user/presentation/users/bloc/user_event.dart|sealed class UserEvent {}',
      'missing Freezed state|invalidFreezedState|src/transfer/presentation/bloc/transfer_state.dart|class TransferState {}',
      "dual runtime database composition|dualRuntimeDatabaseAuthority|app/lib/config/injectable/database_module.dart|import '../database/cootrafa_database.dart';\nimport 'package:feature_auth/database/cootrafa_database.dart';",
      'feature reverse manifest dependency|featureManifestDependsOnApp|features/auth/pubspec.yaml|dependencies:\n  cootrafa_app:\n    path: ../../app',
      'forbidden database abstraction|forbiddenDatabaseAbstraction|src/auth/domain/i_cootrafa_database.dart|abstract class ICootrafaDatabase {}',
      'generic CRUD abstraction|forbiddenDatabaseAbstraction|src/user/domain/i_user_crud.dart|abstract class IUserCrud {}',
      'final feature Drift type|featureDoesNotImportDrift|src/auth/domain/entities/bad_identity.dart|final CootrafaDatabase database;',
      "public barrel closure|publicBarrelLeaksPersistence|auth.dart|export 'src/auth/contracts.dart';|src/auth/contracts.dart|final QueryRow leakedRow;",
      "relative barrel closure|publicBarrelLeaksPersistence|auth.dart|export 'src/auth/api.dart';|src/auth/api.dart|export '../data/contracts.dart';|src/data/contracts.dart|final AddressesData exposedRow;",
      "P7 obsolete persistence|finalFeatureHasInfrastructure|injectable.dart|void configureDependencies() {}|app/lib/config/injectable/injectable_dependency.dart|import 'package:feature_auth/injectable.module.dart';|src/database/cootrafa_database.g.dart|class _GeneratedDatabase {}",
    ];
    for (final String fixture in rejectedFixtures) {
      final List<String> parts = fixture.split('|');
      test('rejects ${parts[0]}', () {
        final BoundaryScanReport report = scanArchitectureSources(
          _sources(parts.sublist(2).join('|')),
          finalArchitecture: parts[0].startsWith('final'),
        );
        expect(
          report.violations.map((BoundaryViolation item) => item.rule),
          contains(BoundaryRule.values.byName(parts[1])),
          reason: report.describeViolations(),
        );
      });
    }

    test('scans the live workspace with only known characterization debt', () {
      final BoundaryScanReport report = scanArchitectureWorkspace(
        findWorkspaceRoot(),
      );

      expect(report.violations, isEmpty, reason: report.describeViolations());
      expect(report.activeExceptions, isEmpty);
    });
  });
}

const Set<String> _temporaryPersistenceExceptions = <String>{
  'src/auth/auth_service.dart',
};

const String _requiredAppPersistence =
    'database/lib/cootrafa_database.dart,database/lib/injectable.dart,database/lib/tables/users.dart,database/lib/tables/login_identifiers.dart,database/lib/tables/addresses.dart,database/lib/tables/transfers.dart,database/lib/tables/local_session.dart,app/lib/config/injectable/injectable_dependency.dart';

enum BoundaryRule {
  appImportsPrivateFeature,
  dualRuntimeDatabaseAuthority,
  featureDoesNotImportApp,
  featureDoesNotImportDrift,
  featureManifestDependsOnApp,
  finalFeatureHasInfrastructure,
  finalArchitectureHasActiveExceptions,
  forbiddenDatabaseAbstraction,
  invalidFreezedEvent,
  invalidFreezedState,
  layerDoesNotImportDataImplementation,
  layerDoesNotImportPersistence,
  persistenceImportsStayInDataSources,
  publicBarrelLeaksPersistence,
  missingFinalAppPersistence,
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

  final BoundaryScanReport report = scanArchitectureSources(
    sources,
    finalArchitecture:
        File('${featureLib.path}/injectable.dart').existsSync() &&
        File('${featureLib.path}/routes.dart').existsSync(),
  );
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

BoundaryScanReport scanArchitectureWorkspace(Directory workspace) {
  const featureNames = <String>['auth', 'user', 'transfer'];
  final List<ArchitectureSource> sources = <ArchitectureSource>[
    for (final feature in featureNames)
      ..._readDartSources(
        Directory('${workspace.path}/packages/features/$feature/lib'),
        'features/$feature/lib/',
      ),
    ..._readDartSources(
      Directory('${workspace.path}/apps/cootrafa-app/lib'),
      'app/lib/',
    ),
    ..._readDartSources(
      Directory('${workspace.path}/packages/database/lib'),
      'database/lib/',
    ),
    for (final feature in featureNames)
      _readSource(
        workspace,
        'packages/features/$feature/pubspec.yaml',
        'features/$feature/pubspec.yaml',
      ),
    _readSource(
      workspace,
      'apps/cootrafa-app/pubspec.yaml',
      'app/pubspec.yaml',
    ),
    _readSource(
      workspace,
      'packages/database/pubspec.yaml',
      'database/pubspec.yaml',
    ),
  ];
  final bool finalArchitecture = featureNames.every((feature) {
    final lib = '${workspace.path}/packages/features/$feature/lib';
    return File('$lib/injectable.dart').existsSync() &&
        File('$lib/routes.dart').existsSync();
  });
  return scanArchitectureSources(
    sources,
    finalArchitecture: finalArchitecture,
    requireAppPersistence: finalArchitecture,
  );
}

Iterable<ArchitectureSource> _readDartSources(Directory root, String prefix) =>
    root
        .listSync(recursive: true)
        .whereType<File>()
        .where((File file) => file.path.endsWith('.dart'))
        .where((File file) => !file.path.endsWith('.config.dart'))
        .where((File file) => !file.path.endsWith('.module.dart'))
        .map(
          (File file) => ArchitectureSource(
            path: '$prefix${_relativePath(root, file)}',
            content: file.readAsStringSync(),
          ),
        );

ArchitectureSource _readSource(
  Directory workspace,
  String physical,
  String normalized,
) => ArchitectureSource(
  path: normalized,
  content: File('${workspace.path}/$physical').readAsStringSync(),
);

BoundaryScanReport scanArchitectureSources(
  List<ArchitectureSource> sources, {
  bool finalArchitecture = false,
  bool requireAppPersistence = false,
}) {
  final List<BoundaryViolation> violations = <BoundaryViolation>[];
  final Set<String> activeExceptions = <String>{};
  final Set<String> sourcePaths = sources
      .map((ArchitectureSource source) => source.path)
      .toSet();
  final bool persistenceFinal =
      sourcePaths.contains('injectable.dart') &&
      sourcePaths.contains(_requiredAppPersistence.split(',').last);
  final bool enforceFinal = finalArchitecture || persistenceFinal;
  final RegExp directive = RegExp(
    r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
  );

  for (final ArchitectureSource source in sources) {
    final String path = source.path.replaceAll('\\', '/');
    final bool appSource = path.startsWith('app/');
    final bool databaseSource = path.startsWith('database/');
    final bool featureSource =
        !appSource &&
        !databaseSource &&
        !RegExp(r'(?:pubspec\.yaml|\.freezed\.dart|\.g\.dart)$').hasMatch(path);
    if (_isFeatureManifest(path) &&
        (source.content.contains('cootrafa_app:') ||
            source.content.contains('apps/cootrafa-app'))) {
      violations.add(
        _sourceViolation(BoundaryRule.featureManifestDependsOnApp, path),
      );
    }
    if (source.content.contains('ICootrafaDatabase') ||
        RegExp(r'\b(?:GenericCrud|I\w*Crud)\b').hasMatch(source.content)) {
      violations.add(
        _sourceViolation(BoundaryRule.forbiddenDatabaseAbstraction, path),
      );
    }
    if (enforceFinal && !appSource && _isInvalidFinalFeaturePath(path)) {
      violations.add(
        _sourceViolation(BoundaryRule.finalFeatureHasInfrastructure, path),
      );
    }
    if (enforceFinal &&
        featureSource &&
        !_isPersistenceOwner(path) &&
        (source.content.contains('CootrafaDatabase') ||
            source.content.contains('QueryRow') ||
            source.content.contains('GeneratedDatabase'))) {
      violations.add(
        _sourceViolation(BoundaryRule.featureDoesNotImportDrift, path),
      );
    }
    final BoundaryRule? freezedFailure = _freezedFailure(source);
    if (freezedFailure != null) {
      violations.add(_sourceViolation(freezedFailure, path));
    }
    final List<String> lines = source.content.split('\n');
    for (int index = 0; index < lines.length; index++) {
      final RegExpMatch? match = directive.firstMatch(lines[index]);
      if (match == null) {
        continue;
      }
      final String importUri = match.group(1)!;
      final bool importsPersistence = _importsPersistence(importUri);

      if (featureSource && _importsApplication(importUri)) {
        violations.add(
          _violation(
            BoundaryRule.featureDoesNotImportApp,
            path,
            index,
            importUri,
          ),
        );
      }
      if (appSource && _importsPrivateFeature(path, importUri)) {
        violations.add(
          _violation(
            BoundaryRule.appImportsPrivateFeature,
            path,
            index,
            importUri,
          ),
        );
      }
      if (featureSource &&
          importUri.startsWith('package:drift/') &&
          !_isPersistenceOwner(path) &&
          !_temporaryPersistenceExceptions.contains(path)) {
        violations.add(
          _violation(
            BoundaryRule.featureDoesNotImportDrift,
            path,
            index,
            importUri,
          ),
        );
      }
      if (_isPublicBarrel(path) && _leaksPersistence(importUri)) {
        violations.add(
          _violation(
            BoundaryRule.publicBarrelLeaksPersistence,
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
    if (appSource &&
        source.content.contains('cootrafa_database.dart') &&
        RegExp(
          r'package:feature_(?:auth|user|transfer)/(?:src/)?database/',
        ).hasMatch(source.content)) {
      violations.add(
        _sourceViolation(BoundaryRule.dualRuntimeDatabaseAuthority, path),
      );
    }
  }

  final Map<String, ArchitectureSource> byPath = <String, ArchitectureSource>{
    for (final ArchitectureSource source in sources) source.path: source,
  };
  for (final ArchitectureSource barrel in sources.where(
    (ArchitectureSource source) => _isPublicBarrel(source.path),
  )) {
    final Set<String> closure = <String>{barrel.path};
    for (int pass = 0; pass < sources.length; pass++) {
      for (final String path in closure.toList()) {
        for (final RegExpMatch export in RegExp(
          r'''export\s+['"]([^'"]+)['"]''',
        ).allMatches(byPath[path]!.content)) {
          final String target = _resolveExport(path, export.group(1)!);
          if (byPath.containsKey(target)) closure.add(target);
        }
      }
    }
    if (closure.any(
      (String path) => _leaksPersistenceContent(byPath[path]!.content),
    )) {
      violations.add(
        _sourceViolation(
          BoundaryRule.publicBarrelLeaksPersistence,
          barrel.path,
        ),
      );
    }
  }

  if (enforceFinal) {
    for (final String path in activeExceptions) {
      violations.add(
        _sourceViolation(
          BoundaryRule.finalArchitectureHasActiveExceptions,
          path,
        ),
      );
    }
  }

  if (enforceFinal && (requireAppPersistence || persistenceFinal)) {
    for (final String path
        in _requiredAppPersistence.split(',').toSet().difference(sourcePaths)) {
      violations.add(
        _sourceViolation(BoundaryRule.missingFinalAppPersistence, path),
      );
    }
  }

  return BoundaryScanReport(
    violations: violations,
    activeExceptions: activeExceptions,
  );
}

BoundaryViolation _sourceViolation(BoundaryRule rule, String path) =>
    BoundaryViolation(rule: rule, path: path, line: 1, importUri: '');

BoundaryRule? _freezedFailure(ArchitectureSource source) {
  final String name = source.path.split('/').last;
  final String stem = name.replaceFirst('.dart', '');
  final String content = source.content;
  if (name.endsWith('_event.dart') && !name.endsWith('.freezed.dart')) {
    final bool valid =
        content.contains('package:freezed_annotation/') &&
        content.contains("part '$stem.freezed.dart';") &&
        content.contains('@freezed') &&
        RegExp(r'sealed class \w+ with _\$\w+').hasMatch(content) &&
        content.contains('const factory');
    return valid ? null : BoundaryRule.invalidFreezedEvent;
  }
  if (name.endsWith('_state.dart') &&
      !name.endsWith('.freezed.dart') &&
      content.contains('class ')) {
    final bool valid =
        content.contains('package:freezed_annotation/') &&
        content.contains("part '$stem.freezed.dart';") &&
        content.contains('@freezed') &&
        RegExp(r'abstract class \w+ with _\$\w+').hasMatch(content) &&
        content.contains('factory');
    return valid ? null : BoundaryRule.invalidFreezedState;
  }
  return null;
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

bool _importsPrivateFeature(String path, String importUri) =>
    RegExp(
      r'^package:feature_(?:auth|user|transfer)/src/',
    ).hasMatch(importUri) ||
    RegExp(
      r'packages/features/(?:auth|user|transfer)/lib/src/',
    ).hasMatch(importUri);

bool _isFeatureManifest(String path) =>
    RegExp(r'^features/(?:auth|user|transfer)/pubspec\.yaml$').hasMatch(path) ||
    path == 'features/pubspec.yaml';

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
    path.startsWith('app/lib/config/database/') ||
    path.startsWith('database/lib/') ||
    path.startsWith('src/database/') ||
    ((path.startsWith('data/datasources/') ||
            path.contains('/data/datasources/')) &&
        path.endsWith('_local_datasource.dart'));

bool _isInvalidFinalFeaturePath(String path) {
  if (path.startsWith('features/')) {
    final match = RegExp(
      r'^features/(?:auth|user|transfer)/lib/(.+)$',
    ).firstMatch(path);
    if (match == null) return false;
    final relative = match.group(1)!;
    final topLevel = relative.split('/').first;
    return !<String>{
      'data',
      'domain',
      'presentation',
      'di',
      'injectable.dart',
      'injectable.module.dart',
      'routes.dart',
    }.contains(topLevel);
  }
  if (!path.startsWith('src/')) return false;
  final String topLevel = path.substring(4).split('/').first;
  return !<String>{'auth', 'user', 'transfer'}.contains(topLevel);
}

bool _isPublicBarrel(String path) {
  final normalized = path.replaceFirst(
    RegExp(r'^features/(?:auth|user|transfer)/lib/'),
    '',
  );
  return const <String>{
    'src/auth/auth.dart',
    'src/user/user.dart',
    'src/transfer/transfer.dart',
    // Legacy paths remain recognized so negative fixtures cannot bypass checks.
    'auth.dart',
    'user.dart',
    'address.dart',
    'transfer.dart',
    'features.dart',
  }.contains(normalized);
}

bool _leaksPersistence(String importUri) =>
    importUri.contains('cootrafa_database') ||
    importUri.endsWith('.g.dart') ||
    importUri.contains('drift_adapter') ||
    importUri.contains('repository_impl') ||
    (importUri.contains('/data/datasources/') &&
        !importUri.split('/').last.startsWith('i_'));

bool _leaksPersistenceContent(String content) => RegExp(
  r'''\b(?:QueryRow|GeneratedDatabase|CootrafaDatabase|DataClass|AddressesData|LocalSessionData)\b|package:drift/|(?:export|import)\s+['"][^'"]*(?:\.g\.dart|cootrafa_database)[^'"]*['"]''',
).hasMatch(content);

String _resolveExport(String path, String uri) =>
    RegExp(r'^package:feature_(auth|user|transfer)/').hasMatch(uri)
    ? uri.replaceFirstMapped(
        RegExp(r'^package:feature_(auth|user|transfer)/'),
        (match) => 'features/${match.group(1)}/lib/',
      )
    : uri.startsWith('package:features/')
    ? uri.substring('package:features/'.length)
    : Uri.parse(path).resolve(uri).path;

String _relativePath(Directory root, File file) =>
    file.path.substring(root.path.length + 1).replaceAll('\\', '/');

Directory findWorkspaceRoot() =>
    File('apps/cootrafa-app/pubspec.yaml').existsSync()
    ? Directory.current
    : Directory.current.parent.parent;

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

List<ArchitectureSource> _finalArchitectureSources() => <ArchitectureSource>[
  ..._sources(
    "injectable.dart|void configureDependencies() {}|data/datasources/auth_local_datasource.dart|import 'package:drift/drift.dart'; abstract interface class IAuthLocalDatasource {}|presentation/auth/bloc/auth_event.dart|import 'package:freezed_annotation/freezed_annotation.dart';\npart 'auth_event.freezed.dart';\n@freezed sealed class AuthEvent with _\$AuthEvent { const factory AuthEvent.restore() = Restore; }|presentation/auth/bloc/auth_state.dart|import 'package:freezed_annotation/freezed_annotation.dart';\npart 'auth_state.freezed.dart';\n@freezed abstract class AuthState with _\$AuthState { const factory AuthState() = _AuthState; }|presentation/auth/bloc/auth_state.freezed.dart|class GeneratedAuthState {}",
  ),
  for (final String path in _requiredAppPersistence.split(','))
    ArchitectureSource(
      path: path,
      content: path.endsWith('injectable_dependency.dart')
          ? "import 'package:cootrafa_database/injectable.module.dart';"
          : path.endsWith('injectable.dart')
          ? "import 'package:injectable/injectable.dart';"
          : "import 'package:drift/drift.dart'; class AppPersistenceConcept {}",
    ),
];

List<ArchitectureSource> _sources(String encoded) => <ArchitectureSource>[
  for (int index = 0; index < encoded.split('|').length; index += 2)
    ArchitectureSource(
      path: encoded.split('|')[index],
      content: encoded.split('|')[index + 1],
    ),
];
