import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:components/theme_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  Widget app(Widget child) {
    final lightTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF004183)),
    );
    final darkTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF004183),
        brightness: Brightness.dark,
      ),
    );
    return AdaptiveTheme(
      light: lightTheme,
      dark: darkTheme,
      initial: AdaptiveThemeMode.light,
      builder: (theme, darkTheme) => MaterialApp(
        theme: theme,
        darkTheme: darkTheme,
        home: Scaffold(body: child),
      ),
    );
  }

  testWidgets('filled variant uses the themed primary color', (tester) async {
    await tester.pumpWidget(app(const ThemeModeButton.filled()));

    final finder = find.byType(FilledButton);
    expect(finder, findsOneWidget);
    expect(find.byType(OutlinedButton), findsNothing);

    final context = tester.element(finder);
    final button = tester.widget<FilledButton>(finder);
    expect(
      button.style?.backgroundColor?.resolve(<WidgetState>{}),
      Theme.of(context).colorScheme.primary,
    );
    expect(
      button.style?.foregroundColor?.resolve(<WidgetState>{}),
      Theme.of(context).colorScheme.onPrimary,
    );
  });

  testWidgets('outlined variant keeps its existing presentation', (
    tester,
  ) async {
    await tester.pumpWidget(app(const ThemeModeButton.outlined()));

    expect(find.byType(OutlinedButton), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
  });
}
