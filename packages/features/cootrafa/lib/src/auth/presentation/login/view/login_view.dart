import 'package:core/get_it.dart';
import 'package:features/src/auth/presentation/auth/bloc/auth_bloc.dart';
import 'package:features/src/auth/presentation/auth/bloc/auth_event.dart';
import 'package:features/src/auth/presentation/auth/bloc/auth_state.dart';
import 'package:features/src/user/presentation/users/view/users_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  static const String path = '/login';
  static const String name = 'login';

  static Widget create() => BlocProvider.value(
    value: getIt<AuthBloc>()..add(const AuthEvent.restoreRequested()),
    child: const LoginView(),
  );

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.message != current.message,
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          context.go(UsersView.path);
        } else if (state.status == AuthStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message ?? 'No fue posible iniciar sesión.'),
            ),
          );
        }
      },
      child: Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  final isLoading = state.status == AuthStatus.loading;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.account_balance, size: 72),
                      const SizedBox(height: 24),
                      Text(
                        'Cootrafa',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 32),
                      FilledButton(
                        onPressed: isLoading
                            ? null
                            : () => context.read<AuthBloc>().add(
                                const AuthEvent.demoAdminLoginRequested(),
                              ),
                        child: isLoading
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Iniciar sesión'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
