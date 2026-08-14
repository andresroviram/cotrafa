import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

enum _Variant { icon, outlined, filled }

class ThemeModeButton extends StatelessWidget {
  const ThemeModeButton._(this.variant);

  const ThemeModeButton.icon() : this._(_Variant.icon);
  const ThemeModeButton.outlined() : this._(_Variant.outlined);
  const ThemeModeButton.filled() : this._(_Variant.filled);

  // ignore: library_private_types_in_public_api
  final _Variant variant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final brightness = Theme.of(context).brightness;
    final (iconData, action, actionLabel) = switch (brightness) {
      Brightness.light => (
        Icons.dark_mode_outlined,
        AdaptiveTheme.of(context).setDark,
        'switch_to_dark'.tr(),
      ),
      Brightness.dark => (
        Icons.light_mode_outlined,
        AdaptiveTheme.of(context).setLight,
        'switch_to_light'.tr(),
      ),
    };

    return switch (variant) {
      _Variant.icon => IconButton(icon: Icon(iconData), onPressed: action),
      _Variant.outlined => OutlinedButton.icon(
        onPressed: action,
        icon: Icon(iconData),
        label: Text(actionLabel),
        style: OutlinedButton.styleFrom(
          backgroundColor: colorScheme.surfaceContainerHighest,
          side: BorderSide(color: colorScheme.secondary.withValues(alpha: 0.5)),
        ),
      ),
      _Variant.filled => FilledButton.icon(
        onPressed: action,
        icon: Icon(iconData),
        label: Text(actionLabel),
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
        ),
      ),
    };
  }
}
