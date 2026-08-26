import 'package:feature_auth/presentation/activation/widgets/activation_content.dart';
import 'package:feature_auth/presentation/auth/bloc/auth_bloc.dart';
import 'package:feature_auth/presentation/auth/bloc/auth_state.dart';
import 'package:feature_auth/presentation/login/view/login_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ActivationMobile extends StatelessWidget {
  const ActivationMobile({
    required this.logoAssetPath,
    required this.logoDarkAssetPath,
    super.key,
  });

  final String logoAssetPath;
  final String logoDarkAssetPath;

  @override
  Widget build(BuildContext context) => BlocBuilder<AuthBloc, AuthState>(
    builder: (context, state) => state.when(
      initial: () => _content(context, isLoading: false),
      loading: () => _content(context, isLoading: true),
      unauthenticated: () => _content(context, isLoading: false),
      authenticated: (_) => _content(context, isLoading: false),
      activationSuccess: (_) => _content(context, isLoading: false),
      failure: (_) => _content(context, isLoading: false),
    ),
  );

  Widget _content(BuildContext context, {required bool isLoading}) =>
      ActivationContent(
        key: const Key('activation-content'),
        logoAssetPath: logoAssetPath,
        logoDarkAssetPath: logoDarkAssetPath,
        isLoading: isLoading,
        onBack: () => context.go(LoginView.path),
      );
}
