import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const primaryColor = Color(0xFF004183);
  static const secondaryColor = Color(0xFFFF8C00);
  static const accentColor = Color(0xFF004EB5);

  static final lightColorScheme = ColorScheme.fromSeed(seedColor: primaryColor)
      .copyWith(
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: secondaryColor,
        onSecondary: Colors.black,
        tertiary: accentColor,
        onTertiary: Colors.white,
        surface: Colors.white,
        onSurface: Colors.black,
      );

  static final darkColorScheme = ColorScheme.fromSeed(
    seedColor: primaryColor,
    brightness: Brightness.dark,
  ).copyWith(secondary: secondaryColor, tertiary: accentColor);

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
