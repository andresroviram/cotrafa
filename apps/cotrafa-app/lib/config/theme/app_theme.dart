import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const primaryColor = Color(0xFF004183);
  static const secondaryColor = Color(0xFFFF8C00);
  static const accentColor = Color(0xFF004EB5);

  static final lightColorScheme = _colorScheme(Brightness.light);
  static final darkColorScheme = _colorScheme(Brightness.dark);

  static final light = _theme(lightColorScheme);
  static final dark = _theme(darkColorScheme);

  static ColorScheme _colorScheme(Brightness brightness) {
    final primary = _seedScheme(primaryColor, brightness);
    final secondary = _seedScheme(secondaryColor, brightness);
    final tertiary = _seedScheme(accentColor, brightness);
    final isLight = brightness == Brightness.light;

    return primary.copyWith(
      primary: isLight ? primaryColor : primary.primary,
      onPrimary: isLight ? Colors.white : primary.onPrimary,
      secondary: secondaryColor,
      onSecondary: Colors.black,
      secondaryContainer: secondary.primaryContainer,
      onSecondaryContainer: secondary.onPrimaryContainer,
      secondaryFixed: secondary.primaryFixed,
      secondaryFixedDim: secondary.primaryFixedDim,
      onSecondaryFixed: secondary.onPrimaryFixed,
      onSecondaryFixedVariant: secondary.onPrimaryFixedVariant,
      tertiary: isLight ? accentColor : tertiary.primary,
      onTertiary: isLight ? Colors.white : tertiary.onPrimary,
      tertiaryContainer: tertiary.primaryContainer,
      onTertiaryContainer: tertiary.onPrimaryContainer,
      tertiaryFixed: tertiary.primaryFixed,
      tertiaryFixedDim: tertiary.primaryFixedDim,
      onTertiaryFixed: tertiary.onPrimaryFixed,
      onTertiaryFixedVariant: tertiary.onPrimaryFixedVariant,
      surface: isLight ? Colors.white : primary.surface,
      onSurface: isLight ? Colors.black : primary.onSurface,
    );
  }

  static ColorScheme _seedScheme(Color seed, Brightness brightness) =>
      ColorScheme.fromSeed(
        seedColor: seed,
        brightness: brightness,
        dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot,
      );

  static ThemeData _theme(ColorScheme colors) =>
      ThemeData.from(colorScheme: colors, useMaterial3: true).copyWith(
        scaffoldBackgroundColor: colors.surfaceContainerLow,
        appBarTheme: AppBarThemeData(
          backgroundColor: colors.surfaceContainerLow,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: _cardTheme(colors),
        inputDecorationTheme: _inputDecorationTheme(colors),
      );

  static CardThemeData _cardTheme(ColorScheme colors) => CardThemeData(
    color: colors.surface,
    elevation: 2,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.45)),
    ),
  );

  static InputDecorationThemeData _inputDecorationTheme(ColorScheme colors) =>
      InputDecorationThemeData(
        filled: true,
        fillColor: colors.brightness == Brightness.light
            ? colors.surface
            : colors.surfaceContainerHighest,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      );
}
