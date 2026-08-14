import 'package:cootrafa_app/config/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses the official Cotrafa brand palette', () {
    final colors = AppTheme.light.colorScheme;

    expect(colors.primary, const Color(0xFF004183));
    expect(colors.secondary, const Color(0xFFFF8C00));
    expect(colors.tertiary, const Color(0xFF004EB5));
    expect(colors.surface, Colors.white);
    expect(colors.onSurface, Colors.black);
  });

  test('uses white cards in light mode and native surfaces in dark mode', () {
    expect(AppTheme.light.cardTheme.color, Colors.white);
    expect(
      AppTheme.dark.cardTheme.color,
      AppTheme.dark.colorScheme.surfaceContainerLow,
    );
  });
}
