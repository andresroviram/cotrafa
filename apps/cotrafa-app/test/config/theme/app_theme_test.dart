import 'package:cotrafa_app/config/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds official Material 3 themes for both brightness modes', () {
    expect(AppTheme.light.useMaterial3, isTrue);
    expect(AppTheme.dark.useMaterial3, isTrue);
    expect(AppTheme.light.brightness, Brightness.light);
    expect(AppTheme.dark.brightness, Brightness.dark);
  });

  test('keeps complete Cotrafa accent color groups', () {
    final colors = AppTheme.light.colorScheme;
    final orange = ColorScheme.fromSeed(
      seedColor: const Color(0xFFFF8C00),
      dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot,
    );
    final accent = ColorScheme.fromSeed(
      seedColor: const Color(0xFF004EB5),
      dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot,
    );

    expect(colors.primary, const Color(0xFF004183));
    expect(colors.secondary, const Color(0xFFFF8C00));
    expect(colors.secondaryContainer, orange.primaryContainer);
    expect(colors.onSecondaryContainer, orange.onPrimaryContainer);
    expect(colors.tertiary, const Color(0xFF004EB5));
    expect(colors.tertiaryContainer, accent.primaryContainer);
    expect(colors.onTertiaryContainer, accent.onPrimaryContainer);
    expect(colors.surface, Colors.white);
    expect(colors.onSurface, Colors.black);

    final darkColors = AppTheme.dark.colorScheme;
    final darkOrange = ColorScheme.fromSeed(
      seedColor: const Color(0xFFFF8C00),
      brightness: Brightness.dark,
      dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot,
    );
    expect(darkColors.secondary, const Color(0xFFFF8C00));
    expect(darkColors.onSecondary, Colors.black);
    expect(darkColors.secondaryContainer, darkOrange.primaryContainer);
    expect(darkColors.onSecondaryContainer, darkOrange.onPrimaryContainer);
  });

  test('centralizes component surfaces without changing the UI', () {
    expect(AppTheme.light.cardTheme.color, AppTheme.light.colorScheme.surface);
    expect(AppTheme.dark.cardTheme.color, AppTheme.dark.colorScheme.surface);
    expect(
      AppTheme.light.scaffoldBackgroundColor,
      AppTheme.light.colorScheme.surfaceContainerLow,
    );
    expect(
      AppTheme.dark.scaffoldBackgroundColor,
      AppTheme.dark.colorScheme.surfaceContainerLow,
    );
    expect(
      AppTheme.light.appBarTheme.backgroundColor,
      AppTheme.light.colorScheme.surfaceContainerLow,
    );
    expect(
      AppTheme.dark.appBarTheme.backgroundColor,
      AppTheme.dark.colorScheme.surfaceContainerLow,
    );
    expect(AppTheme.light.appBarTheme.surfaceTintColor, Colors.transparent);
    expect(AppTheme.dark.appBarTheme.surfaceTintColor, Colors.transparent);
    expect(AppTheme.light.inputDecorationTheme.filled, isTrue);
    expect(
      AppTheme.light.inputDecorationTheme.fillColor,
      AppTheme.light.colorScheme.surface,
    );
    expect(
      AppTheme.dark.inputDecorationTheme.fillColor,
      AppTheme.dark.colorScheme.surfaceContainerHighest,
    );
  });
}
