import 'dart:js_interop';

import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

DatabaseConnection connect(String databaseName) {
  return DatabaseConnection.delayed(
    Future(() async {
      final result = await WasmDatabase.open(
        databaseName: databaseName,
        sqlite3Uri: Uri.parse('sqlite3.wasm'),
        driftWorkerUri: Uri.parse('drift_worker.dart.js'),
      );

      if (result.missingFeatures.isNotEmpty) {
        debugPrint(
          'Using ${result.chosenImplementation} due to missing browser '
          'features: ${result.missingFeatures}',
        );
      }

      final executor = result.resolvedExecutor;

      web.window.addEventListener(
        'beforeunload',
        (web.Event _) {
          executor.close();
        }.toJS,
      );

      return executor;
    }),
  );
}
