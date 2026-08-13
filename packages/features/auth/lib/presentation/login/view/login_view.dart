import 'package:core/get_it.dart';
import 'package:feature_auth/presentation/auth/bloc/auth_bloc.dart';
import 'package:feature_auth/presentation/auth/bloc/auth_event.dart';
import 'package:feature_auth/presentation/auth/bloc/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class LoginView extends StatefulWidget {
  const LoginView({required this.authenticatedLocation, super.key});

  final String authenticatedLocation;

  static const String path = '/login';
  static const String name = 'login';

  static Widget create({required String authenticatedLocation}) =>
      BlocProvider.value(
        value: getIt<AuthBloc>()..add(const AuthEvent.restoreRequested()),
        child: LoginView(authenticatedLocation: authenticatedLocation),
      );

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.message != current.message,
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          context.go(widget.authenticatedLocation);
        } else if (state.status == AuthStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message ?? 'No fue posible iniciar sesión.'),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: colors.surface,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 40,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        final isLoading = state.status == AuthStatus.loading;
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                color: colors.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.account_balance_rounded,
                                color: colors.onPrimaryContainer,
                                size: 38,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Cootrafa',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: colors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Bienvenido',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Administra usuarios y transferencias de forma segura.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: colors.onSurfaceVariant),
                            ),
                            const SizedBox(height: 24),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        'Acceso demo de administrador',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'La credencial configurada se inyecta automáticamente.',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: colors.onSurfaceVariant,
                                            ),
                                      ),
                                      const SizedBox(height: 14),
                                      FilledButton.icon(
                                        onPressed: isLoading
                                            ? null
                                            : () => context.read<AuthBloc>().add(
                                                const AuthEvent.demoAdminLoginRequested(),
                                              ),
                                        icon: const Icon(
                                          Icons.verified_user_outlined,
                                        ),
                                        label: _ButtonLabel(
                                          loading: isLoading,
                                          text: 'Iniciar sesión',
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      Row(
                                        children: [
                                          const Expanded(child: Divider()),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                            ),
                                            child: Text(
                                              'o ingresa como cliente',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelMedium
                                                  ?.copyWith(
                                                    color:
                                                        colors.onSurfaceVariant,
                                                  ),
                                            ),
                                          ),
                                          const Expanded(child: Divider()),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      TextFormField(
                                        controller: _identifierController,
                                        enabled: !isLoading,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        textInputAction: TextInputAction.next,
                                        autocorrect: false,
                                        decoration: _inputDecoration(
                                          context,
                                          label: 'Correo o nombre de usuario',
                                          icon: Icons.person_outline_rounded,
                                        ),
                                        validator: (value) =>
                                            value == null ||
                                                value.trim().isEmpty
                                            ? 'Ingresa tu correo o nombre de usuario.'
                                            : null,
                                      ),
                                      const SizedBox(height: 14),
                                      TextFormField(
                                        controller: _passwordController,
                                        enabled: !isLoading,
                                        obscureText: _obscurePassword,
                                        textInputAction: TextInputAction.done,
                                        onFieldSubmitted: (_) =>
                                            _submitClient(),
                                        decoration:
                                            _inputDecoration(
                                              context,
                                              label: 'Contraseña',
                                              icon: Icons.lock_outline_rounded,
                                            ).copyWith(
                                              suffixIcon: IconButton(
                                                onPressed: () => setState(
                                                  () => _obscurePassword =
                                                      !_obscurePassword,
                                                ),
                                                icon: Icon(
                                                  _obscurePassword
                                                      ? Icons
                                                            .visibility_outlined
                                                      : Icons
                                                            .visibility_off_outlined,
                                                ),
                                              ),
                                            ),
                                        validator: (value) =>
                                            value == null || value.isEmpty
                                            ? 'Ingresa tu contraseña.'
                                            : null,
                                      ),
                                      const SizedBox(height: 16),
                                      OutlinedButton(
                                        onPressed: isLoading
                                            ? null
                                            : _submitClient,
                                        child: const Text(
                                          'Ingresar con mi cuenta',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String label,
    required IconData icon,
  }) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon),
    filled: true,
    fillColor: Theme.of(
      context,
    ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  );

  void _submitClient() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
      AuthEvent.loginRequested(
        _identifierController.text.trim().toLowerCase(),
        _passwordController.text,
      ),
    );
  }
}

class _ButtonLabel extends StatelessWidget {
  const _ButtonLabel({required this.loading, required this.text});

  final bool loading;
  final String text;

  @override
  Widget build(BuildContext context) => loading
      ? const SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
      : Text(text);
}
