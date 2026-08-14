import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class LanguageSwitcherButton extends StatelessWidget {
  const LanguageSwitcherButton({super.key});

  static const _languages = [
    (locale: Locale('es'), labelKey: 'language.spanish', flag: '🇪🇸'),
    (locale: Locale('en'), labelKey: 'language.english', flag: '🇬🇧'),
  ];

  @override
  Widget build(BuildContext context) {
    final current = context.locale;
    return PopupMenuButton<Locale>(
      tooltip: 'language.tooltip'.tr(),
      offset: const Offset(0, 45),
      padding: EdgeInsets.zero,
      icon: Text(
        _languages
            .firstWhere(
              (l) => l.locale.languageCode == current.languageCode,
              orElse: () => _languages.first,
            )
            .flag,
        style: const TextStyle(fontSize: 20),
      ),
      onSelected: (locale) => context.setLocale(locale),
      itemBuilder: (_) => _languages
          .map(
            (l) => PopupMenuItem<Locale>(
              value: l.locale,
              child: Row(
                children: [
                  Text(l.flag, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Text(l.labelKey.tr()),
                  if (l.locale.languageCode == current.languageCode) ...[
                    const Spacer(),
                    Icon(
                      Icons.check,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
