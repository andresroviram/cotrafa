import 'package:components/localized_formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final scenario in [
    (locale: const Locale('es'), currency: '1.234', date: '14/8/2000'),
    (locale: const Locale('en'), currency: '1,234', date: '8/14/2000'),
  ]) {
    testWidgets('formats COP and dates for ${scenario.locale.languageCode}', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: scenario.locale,
          supportedLocales: const [Locale('es'), Locale('en')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Builder(
            builder: (context) => Column(
              children: [
                Text(localizedCop(context, 1234)),
                Text(localizedDate(context, DateTime(2000, 8, 14))),
              ],
            ),
          ),
        ),
      );

      expect(find.textContaining(scenario.currency), findsOneWidget);
      expect(find.text(scenario.date), findsOneWidget);
    });
  }
}
