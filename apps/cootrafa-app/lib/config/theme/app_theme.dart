import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const _seed = Color(0xFF00856A);

  static final lightColorScheme = ColorScheme.fromSeed(seedColor: _seed);

  static final darkColorScheme = ColorScheme.fromSeed(
    seedColor: _seed,
    brightness: Brightness.dark,
  );

  static final light = ThemeData(
    colorScheme: lightColorScheme,
    useMaterial3: true,
    cardTheme: _cardTheme(lightColorScheme),
  );

  static final dark = ThemeData(
    colorScheme: darkColorScheme,
    useMaterial3: true,
    cardTheme: _cardTheme(darkColorScheme),
  );

  static CardThemeData _cardTheme(ColorScheme colors) => CardThemeData(
    color: colors.surfaceContainerLow,
    elevation: 2,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.45)),
    ),
  );
}
