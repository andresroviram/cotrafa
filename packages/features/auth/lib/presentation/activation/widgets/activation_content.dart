import 'package:feature_auth/presentation/auth/bloc/auth_bloc.dart';
import 'package:feature_auth/presentation/auth/bloc/auth_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ActivationContent extends StatefulWidget {
  const ActivationContent({
    required this.logoAssetPath,
    required this.logoDarkAssetPath,
    required this.isLoading,
    required this.onBack,
    super.key,
  });

  final String logoAssetPath;
  final String logoDarkAssetPath;
  final bool isLoading;
  final VoidCallback onBack;

  @override
  State<ActivationContent> createState() => _ActivationContentState();
}

class _ActivationContentState extends State<ActivationContent> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _usernameController.dispose();
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
    return Scaffold(
      backgroundColor: colors.surfaceContainerLow,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 56,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          logoPath,
                          width: 160,
                          height: 54,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const SizedBox(height: 54),
                        ),
                        const SizedBox(height: 24),
                        Card(
                          margin: EdgeInsets.zero,
                          elevation: 0,
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: _form(context),
                          ),
                        ),
                      ],
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

  Widget _form(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Activa tu cuenta',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Usa el código entregado por el administrador y crea tus credenciales.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          _field(
            key: const Key('activation-email'),
            controller: _emailController,
            label: 'Correo electrónico',
            keyboardType: TextInputType.emailAddress,
            validator: _validateEmail,
          ),
          const SizedBox(height: 14),
          _field(
            key: const Key('activation-code'),
            controller: _codeController,
            label: 'Código de activación',
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            validator: (value) => !RegExp(r'^\d{6}$').hasMatch(value ?? '')
                ? 'Ingresa el código de 6 dígitos.'
                : null,
          ),
          const SizedBox(height: 14),
          _field(
            key: const Key('activation-username'),
            controller: _usernameController,
            label: 'Nombre de usuario',
            validator: _validateUsername,
          ),
          const SizedBox(height: 14),
          _field(
            key: const Key('activation-password'),
            controller: _passwordController,
            label: 'Nueva contraseña',
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            validator: _validatePassword,
            suffixIcon: _visibilityButton(),
            onFieldSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('activate-account-submit'),
            onPressed: widget.isLoading ? null : _submit,
            child: widget.isLoading
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Activar cuenta'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: widget.isLoading ? null : widget.onBack,
            child: const Text('Volver al inicio de sesión'),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required Key key,
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    TextInputAction textInputAction = TextInputAction.next,
    List<TextInputFormatter>? inputFormatters,
    bool obscureText = false,
    Widget? suffixIcon,
    ValueChanged<String>? onFieldSubmitted,
  }) => TextFormField(
    key: key,
    controller: controller,
    keyboardType: keyboardType,
    textInputAction: textInputAction,
    inputFormatters: inputFormatters,
    obscureText: obscureText,
    autocorrect: false,
    autovalidateMode: AutovalidateMode.onUserInteraction,
    decoration: InputDecoration(labelText: label, suffixIcon: suffixIcon),
    validator: validator,
    onFieldSubmitted: onFieldSubmitted,
  );

  IconButton _visibilityButton() => IconButton(
    tooltip: _obscurePassword ? 'Mostrar contraseña' : 'Ocultar contraseña',
    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
    icon: Icon(
      _obscurePassword
          ? Icons.visibility_outlined
          : Icons.visibility_off_outlined,
    ),
  );

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Ingresa tu correo electrónico.';
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
        ? null
        : 'Ingresa un correo válido.';
  }

  String? _validateUsername(String? value) {
    final username = value?.trim() ?? '';
    if (username.length < 3) return 'Usa al menos 3 caracteres.';
    return RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(username)
        ? null
        : 'Usa letras, números, punto, guion o guion bajo.';
  }

  String? _validatePassword(String? value) =>
      (value?.length ?? 0) < 8 ? 'Usa al menos 8 caracteres.' : null;

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusManager.instance.primaryFocus?.unfocus();
    context.read<AuthBloc>().add(
      AuthEvent.activationRequested(
        _emailController.text.trim().toLowerCase(),
        _codeController.text.trim(),
        _usernameController.text.trim().toLowerCase(),
        _passwordController.text,
      ),
    );
  }
}
