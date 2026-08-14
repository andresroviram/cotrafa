import 'package:core/get_it.dart';
import 'package:core/utils/notifications.dart';
import 'package:feature_auth/presentation/auth/bloc/auth_bloc.dart';
import 'package:feature_auth/presentation/auth/bloc/auth_event.dart';
import 'package:feature_auth/presentation/auth/bloc/auth_state.dart';
import 'package:feature_auth/presentation/login/view/login_mobile.dart';
import 'package:feature_auth/presentation/login/view/login_web.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';

class LoginView extends StatelessWidget {
  const LoginView({
    required this.authenticatedLocation,
    required this.logoAssetPath,
    required this.logoDarkAssetPath,
    super.key,
  });

  final String authenticatedLocation;
  final String logoAssetPath;
  final String logoDarkAssetPath;

  static const String path = '/login';
  static const String name = 'login';

  static Widget create({
    required String authenticatedLocation,
    required String logoAssetPath,
    required String logoDarkAssetPath,
  }) => BlocProvider.value(
    value: getIt<AuthBloc>()..add(const AuthEvent.restoreRequested()),
    child: LoginView(
      authenticatedLocation: authenticatedLocation,
      logoAssetPath: logoAssetPath,
      logoDarkAssetPath: logoDarkAssetPath,
    ),
  );

  @override
  Widget build(BuildContext context) => BlocListener<AuthBloc, AuthState>(
    listenWhen: (previous, current) =>
        previous.status != current.status ||
        previous.message != current.message,
    listener: _onStateChanged,
    child: ResponsiveBreakpoints.of(context).largerThan(MOBILE)
        ? LoginWeb(
            logoAssetPath: logoAssetPath,
            logoDarkAssetPath: logoDarkAssetPath,
          )
        : LoginMobile(
            logoAssetPath: logoAssetPath,
            logoDarkAssetPath: logoDarkAssetPath,
          ),
  );

  void _onStateChanged(BuildContext context, AuthState state) {
    if (state.status == AuthStatus.authenticated) {
      context.go(authenticatedLocation);
      return;
    }
    if (state.status == AuthStatus.failure) {
      AppNotification.showNotificationError(
        context,
        title: state.message ?? 'No fue posible iniciar sesión.',
      );
    }
  }
}
