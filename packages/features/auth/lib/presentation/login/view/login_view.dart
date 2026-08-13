import 'package:core/get_it.dart';
import 'package:feature_auth/presentation/auth/bloc/auth_bloc.dart';
import 'package:feature_auth/presentation/auth/bloc/auth_event.dart';
import 'package:feature_auth/presentation/auth/bloc/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class LoginView extends StatefulWidget {
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final logoPath = theme.brightness == Brightness.dark
        ? widget.logoDarkAssetPath
        : widget.logoAssetPath;

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
        backgroundColor: colors.surfaceContainerLow,
        body: SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.manual,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 28,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 56,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          final isLoading = state.status == AuthStatus.loading;
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Semantics(
                                label: 'Logo de Cootrafa',
                                image: true,
                                child: Image.asset(
                                  logoPath,
                                  width: 176,
                                  height: 60,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, _, _) =>
                                      const SizedBox(height: 60),
                                ),
                              ),
                              const SizedBox(height: 28),
                              Card(
                                margin: EdgeInsets.zero,
                                color: colors.surface,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    24,
                                    32,
                                    24,
                                    28,
                                  ),
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Text(
                                          'Bienvenido',
                                          textAlign: TextAlign.center,
                                          style: theme.textTheme.headlineSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        const SizedBox(height: 28),
                                        const _FieldLabel(
                                          text: 'Correo o nombre de usuario',
                                        ),
                                        const SizedBox(height: 8),
                                        TextFormField(
                                          controller: _identifierController,
                                          enabled: !isLoading,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          textInputAction: TextInputAction.next,
                                          autocorrect: false,
                                          autofillHints: const [
                                            AutofillHints.username,
                                            AutofillHints.email,
                                          ],
                                          decoration: _inputDecoration(
                                            context,
                                            hint: 'tu@correo.com',
                                          ),
                                          validator: (value) =>
                                              value == null ||
                                                  value.trim().isEmpty
                                              ? 'Ingresa tu correo o nombre de usuario.'
                                              : null,
                                        ),
                                        const SizedBox(height: 14),
                                        const _FieldLabel(text: 'Contraseña'),
                                        const SizedBox(height: 8),
                                        TextFormField(
                                          controller: _passwordController,
                                          enabled: !isLoading,
                                          obscureText: _obscurePassword,
                                          textInputAction: TextInputAction.done,
                                          autovalidateMode: AutovalidateMode
                                              .onUserInteraction,
                                          autofillHints: const [
                                            AutofillHints.password,
                                          ],
                                          onFieldSubmitted: (_) =>
                                              _submitClient(),
                                          decoration:
                                              _inputDecoration(
                                                context,
                                                hint: 'Ingresa tu contraseña',
                                              ).copyWith(
                                                suffixIcon: IconButton(
                                                  tooltip: _obscurePassword
                                                      ? 'Mostrar contraseña'
                                                      : 'Ocultar contraseña',
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
                                        const SizedBox(height: 24),
                                        FilledButton(
                                          style: _buttonStyle(),
                                          onPressed: isLoading
                                              ? null
                                              : _submitClient,
                                          child: _ButtonLabel(
                                            loading: isLoading,
                                            text: 'Iniciar sesión',
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        OutlinedButton(
                                          style: _buttonStyle(),
                                          onPressed: isLoading
                                              ? null
                                              : () => context.read<AuthBloc>().add(
                                                  const AuthEvent.demoAdminLoginRequested(),
                                                ),
                                          child: const Text(
                                            'Iniciar como Admin',
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
      ),
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String hint,
  }) {
    final colors = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(16);
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: colors.onSurfaceVariant),
      filled: true,
      fillColor: colors.surfaceContainerHighest.withValues(alpha: 0.5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: colors.primary, width: 1.4),
      ),
    );
  }

  ButtonStyle _buttonStyle() => ButtonStyle(
    minimumSize: const WidgetStatePropertyAll(Size.fromHeight(52)),
    shape: const WidgetStatePropertyAll(StadiumBorder()),
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

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(
      context,
    ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
  );
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
