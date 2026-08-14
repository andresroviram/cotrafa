import 'package:feature_user/domain/entities/user_profile.dart';
import 'package:feature_user/presentation/users/activation_code_issuer.dart';
import 'package:feature_user/presentation/users/bloc/user_bloc.dart';
import 'package:feature_user/presentation/users/bloc/user_event.dart';
import 'package:feature_user/presentation/users/bloc/user_state.dart';
import 'package:feature_user/presentation/users/widgets/activation_code_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserCreateForm extends StatefulWidget {
  const UserCreateForm({
    super.key,
    required this.actorUserId,
    required this.issueActivationCode,
  });

  final int actorUserId;
  final ActivationCodeIssuer issueActivationCode;

  @override
  State<UserCreateForm> createState() => _UserCreateFormState();
}

class _UserCreateFormState extends State<UserCreateForm> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _balanceController = TextEditingController(text: '0');
  bool _handledCreation = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserBloc, UserState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: _onStateChanged,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
          padding: EdgeInsets.fromLTRB(
            24,
            8,
            24,
            24 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Nuevo usuario',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  key: const Key('create-user-full-name'),
                  controller: _fullNameController,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Ingresa el nombre completo'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('create-user-email'),
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: _validateEmail,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('create-user-balance'),
                  controller: _balanceController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Saldo inicial',
                    prefixText: r'$ ',
                    helperText: 'Valor en pesos colombianos',
                  ),
                  validator: _validateBalance,
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 24),
                BlocBuilder<UserBloc, UserState>(
                  buildWhen: (previous, current) =>
                      previous.status != current.status,
                  builder: (context, state) => FilledButton(
                    key: const Key('create-user-submit'),
                    onPressed: state.status == UserStatus.loading
                        ? null
                        : _submit,
                    child: state.status == UserStatus.loading
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Crear usuario'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Ingresa el correo electrónico';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Ingresa un correo válido';
    }
    return null;
  }

  String? _validateBalance(String? value) {
    final balance = int.tryParse(value ?? '');
    if (balance == null || balance < 0) return 'Ingresa un saldo válido';
    return null;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusManager.instance.primaryFocus?.unfocus();
    _handledCreation = false;
    context.read<UserBloc>().add(
      UserEvent.createRequested(
        widget.actorUserId,
        email: _emailController.text.trim(),
        fullName: _fullNameController.text.trim(),
        initialBalanceCop: int.parse(_balanceController.text),
      ),
    );
  }

  Future<void> _onStateChanged(BuildContext context, UserState state) async {
    if (state.status == UserStatus.failure) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos crear el usuario')),
      );
      return;
    }
    if (state.status != UserStatus.created || _handledCreation) return;
    _handledCreation = true;
    final createdUser = _createdUser(state.users);
    final code = await widget.issueActivationCode(
      widget.actorUserId,
      createdUser.email,
    );
    if (!context.mounted) return;
    if (code == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Usuario creado. Genera su código desde la lista de usuarios.',
          ),
        ),
      );
    } else {
      await showActivationCodeDialog(context, code: code);
    }
    if (context.mounted) Navigator.of(context).pop();
  }

  UserProfile _createdUser(List<UserProfile> users) => users.lastWhere(
    (user) => user.email == _emailController.text.trim(),
    orElse: () => users.last,
  );
}
