import 'package:bot_toast/bot_toast.dart';
import 'package:components/language_switcher.dart';
import 'package:components/layout/scaffold_with_navigation.dart';
import 'package:components/theme_button.dart';
import 'package:core/enum/navigation_item.dart';
import 'package:features/auth.dart';
import 'package:features/routes.dart';
import 'package:features/user.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';

@module
abstract class RouterModule {
  @singleton
  GoRouter router(AuthBloc authBloc) => createRouter(authBloc);
}

GoRouter createRouter(AuthBloc authBloc) {
  final rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  return GoRouter(
    navigatorKey: rootKey,
    debugLogDiagnostics: kDebugMode,
    initialLocation: LoginView.path,
    observers: [BotToastNavigatorObserver()],
    redirect: (_, state) {
      final isAuthenticated = switch (authBloc.state.status) {
        AuthStatus.authenticated || AuthStatus.activationSuccess => true,
        _ => false,
      };
      final isLogin = state.matchedLocation == LoginView.path;
      if (!isAuthenticated && !isLogin) return LoginView.path;
      if (isAuthenticated && isLogin) return UsersView.path;
      return null;
    },
    routes: [
      loginRoute,
      StatefulShellRoute.indexedStack(
        builder: (context, _, navigationShell) => BlocProvider.value(
          value: authBloc,
          child: BlocListener<AuthBloc, AuthState>(
            listenWhen: (previous, current) =>
                previous.status != current.status,
            listener: (context, state) {
              if (state.status == AuthStatus.unauthenticated) {
                context.go(LoginView.path);
              }
            },
            child: ScaffoldWithNavigation(
              navigationShell: navigationShell,
              logoPath: 'assets/img/logo.png',
              logoDarkPath: 'assets/img/logo_dark.png',
              navigationItems: const [
                NavigationItem.home,
                NavigationItem.transactions,
              ],
              appBarActions: [
                const ThemeModeButton.icon(),
                const LanguageSwitcherButton(),
                IconButton(
                  tooltip: 'Cerrar sesión',
                  onPressed: () => context.read<AuthBloc>().add(
                    const AuthEvent.logoutRequested(),
                  ),
                  icon: const Icon(Icons.logout),
                ),
                const Gap(2),
              ],
            ),
          ),
        ),
        branches: [usersRoutes, transferRoutes],
      ),
    ],
  );
}
