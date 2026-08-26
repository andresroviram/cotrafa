import 'package:bot_toast/bot_toast.dart';
import 'package:components/language_switcher.dart';
import 'package:components/layout/scaffold_with_navigation.dart';
import 'package:components/theme_button.dart';
import 'package:core/enum/navigation_item.dart';
import 'package:core/errors/result.dart';
import 'package:core/get_it.dart';
import 'package:feature_auth/domain/usecases/auth_usecases.dart';
import 'package:feature_auth/domain/entities/auth_identity.dart';
import 'package:feature_auth/presentation/activation/view/activation_view.dart';
import 'package:feature_auth/presentation/auth/bloc/auth_bloc.dart';
import 'package:feature_auth/presentation/auth/bloc/auth_event.dart';
import 'package:feature_auth/presentation/auth/bloc/auth_state.dart';
import 'package:feature_auth/presentation/login/view/login_view.dart';
import 'package:feature_auth/routes.dart';
import 'package:feature_transfer/routes.dart';
import 'package:feature_user/presentation/users/view/users_view.dart';
import 'package:feature_user/routes.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';

@module
abstract class RouterModule {
  @lazySingleton
  GoRouter router(AuthBloc authBloc) => createRouter(authBloc);
}

GoRouter createRouter(AuthBloc authBloc) {
  final rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  final authRefresh = _AuthRouterRefresh(authBloc.stream);
  return GoRouter(
    navigatorKey: rootKey,
    debugLogDiagnostics: kDebugMode,
    initialLocation: LoginView.path,
    refreshListenable: authRefresh,
    observers: [BotToastNavigatorObserver()],
    redirect: (_, state) {
      final isAuthenticated = authBloc.state.when(
        initial: () => false,
        loading: () => false,
        unauthenticated: () => false,
        authenticated: (_) => true,
        activationSuccess: (_) => true,
        failure: (_) => false,
      );
      final isPublicAuth =
          state.matchedLocation == LoginView.path ||
          state.matchedLocation == ActivationView.path;
      if (!isAuthenticated && !isPublicAuth) return LoginView.path;
      if (isAuthenticated && isPublicAuth) return UsersView.path;
      return null;
    },
    routes: [
      loginRoute(
        authenticatedLocation: UsersView.path,
        logoAssetPath: 'assets/img/logo.png',
        logoDarkAssetPath: 'assets/img/logo_dark.png',
      ),
      activationRoute(
        authenticatedLocation: UsersView.path,
        logoAssetPath: 'assets/img/logo.png',
        logoDarkAssetPath: 'assets/img/logo_dark.png',
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, _, navigationShell) => BlocProvider.value(
          value: authBloc,
          child: BlocListener<AuthBloc, AuthState>(
            listenWhen: (previous, current) => previous != current,
            listener: (context, state) => state.when<void>(
              initial: () {},
              loading: () {},
              unauthenticated: () => context.go(LoginView.path),
              authenticated: (_) {},
              activationSuccess: (_) {},
              failure: (_) {},
            ),
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
                  tooltip: 'nav.logout'.tr(),
                  onPressed: () =>
                      authBloc.add(const AuthEvent.logoutRequested()),
                  icon: const Icon(Icons.logout),
                ),
                const Gap(2),
              ],
            ),
          ),
        ),
        branches: [
          usersRoutes(
            parentNavigatorKey: rootKey,
            actorUserId: () => _identity(authBloc.state)?.userId ?? -1,
            isAdmin: () => _identity(authBloc.state)?.role == 'admin',
            issueActivationCode: (actorUserId, email) async {
              final result = await getIt<IssueActivationCode>()(
                actorUserId,
                email,
              );
              return result.valueOrNull;
            },
          ),
          transferRoutes(
            parentNavigatorKey: rootKey,
            actorUserId: () => _identity(authBloc.state)?.userId ?? -1,
            isAdmin: () => _identity(authBloc.state)?.role == 'admin',
          ),
        ],
      ),
    ],
  );
}

AuthIdentity? _identity(AuthState state) => state.when(
  initial: () => null,
  loading: () => null,
  unauthenticated: () => null,
  authenticated: (identity) => identity,
  activationSuccess: (identity) => identity,
  failure: (_) => null,
);

final class _AuthRouterRefresh extends ChangeNotifier {
  _AuthRouterRefresh(Stream<AuthState> states) {
    states.listen((_) => notifyListeners());
  }
}
