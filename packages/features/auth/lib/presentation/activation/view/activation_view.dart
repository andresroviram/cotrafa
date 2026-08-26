import 'package:core/get_it.dart';
import 'package:core/utils/notifications.dart';
import 'package:feature_auth/presentation/activation/view/activation_mobile.dart';
import 'package:feature_auth/presentation/activation/view/activation_web.dart';
import 'package:feature_auth/presentation/auth/bloc/auth_bloc.dart';
import 'package:feature_auth/presentation/auth/bloc/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';

class ActivationView extends StatelessWidget {
  const ActivationView({
    required this.authenticatedLocation,
    required this.logoAssetPath,
    required this.logoDarkAssetPath,
    super.key,
  });

  final String authenticatedLocation;
  final String logoAssetPath;
  final String logoDarkAssetPath;

  static const String path = '/activate';
  static const String name = 'activate';

  static Widget create({
    required String authenticatedLocation,
    required String logoAssetPath,
    required String logoDarkAssetPath,
  }) => BlocProvider.value(
    value: getIt<AuthBloc>(),
    child: ActivationView(
      authenticatedLocation: authenticatedLocation,
      logoAssetPath: logoAssetPath,
      logoDarkAssetPath: logoDarkAssetPath,
    ),
  );

  @override
  Widget build(BuildContext context) => BlocListener<AuthBloc, AuthState>(
    listenWhen: (previous, current) => previous != current,
    listener: _onStateChanged,
    child: ResponsiveBreakpoints.of(context).largerThan(MOBILE)
        ? ActivationWeb(
            logoAssetPath: logoAssetPath,
            logoDarkAssetPath: logoDarkAssetPath,
          )
        : ActivationMobile(
            logoAssetPath: logoAssetPath,
            logoDarkAssetPath: logoDarkAssetPath,
          ),
  );

  void _onStateChanged(BuildContext context, AuthState state) {
    state.when(
      initial: () {},
      loading: () {},
      unauthenticated: () {},
      authenticated: (_) {},
      activationSuccess: (_) => context.go(authenticatedLocation),
      failure: (message) =>
          AppNotification.showNotificationError(context, title: message),
    );
  }
}
