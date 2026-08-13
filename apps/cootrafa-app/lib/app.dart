import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:cootrafa_app/config/env/app_flavor.dart';
import 'package:cootrafa_app/config/theme/app_theme.dart';
import 'package:core/get_it.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveTheme(
      light: AppTheme.light,
      dark: AppTheme.dark,
      initial: AdaptiveThemeMode.system,
      builder: (theme, darkTheme) => Builder(
        builder: (ctx) => ResponsiveBreakpoints.builder(
          breakpoints: const [
            Breakpoint(start: 0, end: 450, name: MOBILE),
            Breakpoint(start: 451, end: 960, name: TABLET),
            Breakpoint(start: 961, end: double.infinity, name: DESKTOP),
          ],
          child: MaterialApp.router(
            onGenerateTitle: (_) => 'app_title'.tr(),
            debugShowCheckedModeBanner: false,
            theme: theme,
            darkTheme: darkTheme,
            routerConfig: getIt<GoRouter>(),
            localizationsDelegates: ctx.localizationDelegates,
            supportedLocales: ctx.supportedLocales,
            locale: ctx.locale,
            builder: (context, child) {
              final content = BotToastInit()(context, child);
              if (!kFlavor.showBanner) return content;
              return Banner(
                message: kFlavor.label,
                location: BannerLocation.topEnd,
                color: Color(kFlavor.bannerColor),
                child: content,
              );
            },
          ),
        ),
      ),
    );
  }
}
