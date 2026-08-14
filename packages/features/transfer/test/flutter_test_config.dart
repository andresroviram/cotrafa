// ignore_for_file: implementation_imports

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:easy_localization/src/localization.dart';
import 'package:easy_localization/src/translations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_CO');
  binding.platformDispatcher.localeTestValue = const Locale('es');
  final translations = Translations(_loadCatalog('es'));
  Localization.load(
    const Locale('es'),
    translations: translations,
    fallbackTranslations: translations,
  );
  try {
    await testMain();
  } finally {
    binding.platformDispatcher.clearLocaleTestValue();
  }
}

Map<String, dynamic> _loadCatalog(String languageCode) {
  var directory = Directory.current.absolute;
  while (true) {
    final file = File(
      '${directory.path}/apps/cotrafa-app/assets/translations/'
      '$languageCode.json',
    );
    if (file.existsSync()) {
      return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    }
    final parent = directory.parent;
    if (parent.path == directory.path) {
      throw StateError('Cotrafa translation catalog not found.');
    }
    directory = parent;
  }
}
