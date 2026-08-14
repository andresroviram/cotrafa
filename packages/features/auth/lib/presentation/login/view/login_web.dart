import 'package:feature_auth/presentation/activation/view/activation_view.dart';
import 'package:feature_auth/presentation/auth/bloc/auth_bloc.dart';
import 'package:feature_auth/presentation/auth/bloc/auth_state.dart';
import 'package:feature_auth/presentation/auth/bloc/auth_state_x.dart';
import 'package:feature_auth/presentation/login/widgets/login_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class LoginWeb extends StatelessWidget {
  const LoginWeb({
    required this.logoAssetPath,
    required this.logoDarkAssetPath,
    super.key,
  });

  final String logoAssetPath;
  final String logoDarkAssetPath;

  @override
  Widget build(BuildContext context) => BlocBuilder<AuthBloc, AuthState>(
    builder: (context, state) => state.resolve(
      loading: () => _content(context, isLoading: true),
      failure: (_) => _content(context, isLoading: false),
      data: (_) => _content(context, isLoading: false),
    ),
  );

  Widget _content(BuildContext context, {required bool isLoading}) =>
      LoginContent(
        key: const Key('login-content'),
        logoAssetPath: logoAssetPath,
        logoDarkAssetPath: logoDarkAssetPath,
        isLoading: isLoading,
        onActivation: () => context.go(ActivationView.path),
      );
}
