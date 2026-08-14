import 'package:cotrafa_app/main.dart' as app;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'admin creates a client who activates, adds an address, and transfers',
    (tester) async {
      await app.main();
      await _waitFor(tester, find.byType(MaterialApp));
      await tester
          .element(find.byType(MaterialApp))
          .setLocale(const Locale('es'));
      await tester.pumpAndSettle();
      await _waitForAny(tester, [
        find.text('Bienvenido'),
        find.byTooltip('Cerrar sesión'),
      ]);
      await _signInAsAdmin(tester);

      final suffix = DateTime.now().microsecondsSinceEpoch.toString();
      final clientName = 'Cliente E2E $suffix';
      final email = 'cliente.$suffix@cotrafa.test';
      final username = 'cliente_$suffix';
      const password = 'CotrafaE2E2026!';

      await _tap(tester, find.byKey(const Key('create-user-action')));
      await _enter(
        tester,
        find.byKey(const Key('create-user-first-name')),
        'Cliente E2E',
      );
      await _enter(
        tester,
        find.byKey(const Key('create-user-last-name')),
        suffix,
      );
      await _enter(tester, find.byKey(const Key('create-user-email')), email);
      await _enter(
        tester,
        find.byKey(const Key('create-user-balance')),
        '250000',
      );
      await _tap(tester, find.byKey(const Key('create-user-submit')));

      final activationCodeFinder = find.byKey(
        const Key('activation-code-value'),
      );
      await _waitFor(tester, activationCodeFinder);
      final activationCode = tester
          .widget<SelectableText>(activationCodeFinder)
          .data!;
      expect(activationCode, matches(RegExp(r'^\d{6}$')));

      await _tap(tester, find.text('Entendido'));
      await _waitFor(tester, find.text(clientName));
      await _tap(tester, find.byTooltip('Cerrar sesión'));
      await _waitFor(tester, find.text('Bienvenido'));

      await _tap(tester, find.text('Activar cuenta'));
      await _enter(tester, find.byKey(const Key('activation-email')), email);
      await _enter(
        tester,
        find.byKey(const Key('activation-code')),
        activationCode,
      );
      await _enter(
        tester,
        find.byKey(const Key('activation-username')),
        username,
      );
      await _enter(
        tester,
        find.byKey(const Key('activation-password')),
        password,
      );
      await _tap(tester, find.byKey(const Key('activate-account-submit')));

      await _waitFor(tester, find.text('Lista de usuarios'));
      expect(find.byKey(const Key('create-user-action')), findsNothing);
      await _tap(tester, find.text(clientName));
      await _waitFor(tester, find.byKey(const Key('user-available-balance')));
      expect(
        find.descendant(
          of: find.byKey(const Key('user-available-balance')),
          matching: find.textContaining('250.000'),
        ),
        findsOneWidget,
      );

      await _tap(tester, find.text('Direcciones'));
      await _waitFor(tester, find.byKey(const Key('create-address-action')));
      await _tap(tester, find.byKey(const Key('create-address-action')));
      await _enter(
        tester,
        find.byKey(const Key('address-line-1')),
        'Calle 10 # 20-30',
      );
      await _enter(
        tester,
        find.byKey(const Key('address-line-2')),
        'El Poblado',
      );
      await _enter(tester, find.byKey(const Key('address-city')), 'Medellín');
      await _enter(tester, find.byKey(const Key('address-state')), 'Antioquia');
      await _enter(
        tester,
        find.byKey(const Key('address-postal-code')),
        '050021',
      );
      await _tap(tester, find.byKey(const Key('address-submit')));

      await _waitFor(tester, find.text('Calle 10 # 20-30'));
      expect(find.text('Principal'), findsOneWidget);
      await _goBack(tester);
      await _waitFor(tester, find.byKey(const Key('user-available-balance')));
      await _goBack(tester);
      await _waitFor(tester, find.text('Lista de usuarios'));

      await _tap(tester, find.byIcon(Icons.receipt_long_outlined));
      await _waitFor(tester, find.byKey(const Key('transfer-create-fab')));
      await _tap(tester, find.byKey(const Key('transfer-create-fab')));
      await _waitFor(tester, find.byKey(const Key('transfer-client-origin')));

      await _tap(tester, _byKeyPrefix('transfer-destination-'));
      final adminDestination = find.textContaining('Cotrafa Demo Admin').last;
      await _tap(tester, adminDestination);
      await _enter(tester, find.byKey(const Key('transfer-amount')), '10000');
      await _enter(
        tester,
        find.byKey(const Key('transfer-description')),
        'Transferencia de integración $suffix',
      );
      await _tap(tester, find.byKey(const Key('transfer-submit')));

      await _waitFor(tester, find.byKey(const Key('transfer-result-success')));
      expect(find.byKey(const Key('transfer-receipt')), findsOneWidget);
      await _tap(tester, find.text('Volver al historial'));
      final history = find.byKey(const Key('transfer-history-list'));
      await _waitFor(tester, history);
      expect(
        find.descendant(
          of: history,
          matching: find.text('Transferencia de integración $suffix'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: history, matching: find.text('Enviada')),
        findsOneWidget,
      );
    },
  );
}

Future<void> _signInAsAdmin(WidgetTester tester) async {
  final logout = find.byTooltip('Cerrar sesión');
  if (logout.evaluate().isNotEmpty) {
    await _tap(tester, logout);
    await _waitFor(tester, find.text('Bienvenido'));
  }
  await _tapEnabledFilledButton(
    tester,
    find.byKey(const Key('admin-login-action')),
  );
  await _waitFor(tester, find.byKey(const Key('create-user-action')));
  expect(find.text('Lista de usuarios'), findsOneWidget);
  expect(find.byKey(const Key('create-user-action')), findsOneWidget);
}

Finder _byKeyPrefix(String prefix) => find.byWidgetPredicate((widget) {
  final key = widget.key;
  return key is ValueKey<String> && key.value.startsWith(prefix);
});

Future<void> _enter(WidgetTester tester, Finder finder, String value) async {
  await _waitFor(tester, finder);
  await tester.ensureVisible(finder.first);
  await tester.enterText(finder.first, value);
  await tester.pump(const Duration(milliseconds: 150));
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await _waitFor(tester, finder);
  await tester.ensureVisible(finder.last);
  await tester.pump(const Duration(milliseconds: 100));
  final tappable = finder.hitTestable();
  await _waitFor(tester, tappable);
  await tester.tap(tappable.last);
  await tester.pump(const Duration(milliseconds: 250));
}

Future<void> _goBack(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pump(const Duration(milliseconds: 250));
}

Future<void> _tapEnabledFilledButton(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  await _waitFor(tester, finder, timeout: timeout);
  await tester.ensureVisible(finder.last);
  await tester.pump(const Duration(milliseconds: 100));
  final deadline = DateTime.now().add(timeout);
  var tappable = finder.hitTestable();
  while ((tappable.evaluate().isEmpty ||
          tester.widget<FilledButton>(tappable.last).onPressed == null) &&
      DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
    tappable = finder.hitTestable();
  }
  expect(tappable, findsWidgets);
  expect(tester.widget<FilledButton>(tappable.last).onPressed, isNotNull);
  await tester.tap(tappable.last);
  await tester.pump(const Duration(milliseconds: 250));
}

Future<void> _waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (finder.evaluate().isEmpty && DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(finder, findsWidgets);
}

Future<void> _waitForAny(
  WidgetTester tester,
  List<Finder> finders, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (finders.every((finder) => finder.evaluate().isEmpty) &&
      DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(finders.any((finder) => finder.evaluate().isNotEmpty), isTrue);
}
