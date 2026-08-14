import 'package:feature_user/domain/entities/user_profile.dart';
import 'package:feature_user/presentation/users/activation_code_issuer.dart';
import 'package:feature_user/presentation/users/bloc/user_bloc.dart';
import 'package:feature_user/presentation/users/bloc/user_event.dart';
import 'package:feature_user/presentation/users/bloc/user_state.dart';
import 'package:feature_user/presentation/users/widgets/activation_code_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class UserForm extends StatefulWidget {
  const UserForm.create({
    required this.actorUserId,
    required ActivationCodeIssuer this.issueActivationCode,
    this.showHeading = true,
    super.key,
  }) : user = null;

  const UserForm.edit({
    required this.actorUserId,
    required UserProfile this.user,
    this.showHeading = true,
    super.key,
  }) : issueActivationCode = null;

  final int actorUserId;
  final UserProfile? user;
  final ActivationCodeIssuer? issueActivationCode;
  final bool showHeading;

  bool get isEditing => user != null;

  @override
  State<UserForm> createState() => _UserFormState();
}

class _UserFormState extends State<UserForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _balanceController;
  late DateTime? _birthDate;
  bool _submitted = false;

  String get _keyPrefix => widget.isEditing ? 'edit-user' : 'create-user';

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    _firstNameController = TextEditingController(text: user?.firstName);
    _lastNameController = TextEditingController(text: user?.lastName);
    _phoneController = TextEditingController(text: user?.phone);
    _emailController = TextEditingController(text: user?.email);
    _balanceController = TextEditingController(text: '0');
    _birthDate = user?.birthDate;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocListener<UserBloc, UserState>(
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
              if (widget.showHeading) ...[
                Text(
                  widget.isEditing ? 'Editar usuario' : 'Nuevo usuario',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
              ],
              TextFormField(
                key: Key('$_keyPrefix-first-name'),
                controller: _firstNameController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) => _validateName(value, 'nombre'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: Key('$_keyPrefix-last-name'),
                controller: _lastNameController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Apellido',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (value) => _validateName(value, 'apellido'),
              ),
              const SizedBox(height: 16),
              InkWell(
                key: Key('$_keyPrefix-birth-date'),
                onTap: _selectBirthDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Fecha de nacimiento',
                    prefixIcon: const Icon(Icons.cake_outlined),
                    suffixIcon: _birthDate == null
                        ? const Icon(Icons.calendar_today_outlined)
                        : IconButton(
                            tooltip: 'Borrar fecha',
                            onPressed: () => setState(() => _birthDate = null),
                            icon: const Icon(Icons.clear),
                          ),
                  ),
                  child: Text(
                    _birthDate == null
                        ? 'Sin registrar'
                        : DateFormat('dd/MM/yyyy').format(_birthDate!),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: Key('$_keyPrefix-phone'),
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: Key('$_keyPrefix-email'),
                controller: _emailController,
                readOnly: widget.isEditing,
                keyboardType: TextInputType.emailAddress,
                textInputAction: widget.isEditing
                    ? TextInputAction.done
                    : TextInputAction.next,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: 'Correo electrónico',
                  prefixIcon: const Icon(Icons.email_outlined),
                  helperText: widget.isEditing
                      ? 'El correo no se puede modificar'
                      : null,
                ),
                validator: _validateEmail,
                onFieldSubmitted: widget.isEditing ? (_) => _submit() : null,
              ),
              if (!widget.isEditing) ...[
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
              ],
              const SizedBox(height: 24),
              BlocBuilder<UserBloc, UserState>(
                buildWhen: (previous, current) =>
                    previous.status != current.status,
                builder: (context, state) => FilledButton(
                  key: Key('$_keyPrefix-submit'),
                  onPressed: state.status == UserStatus.loading
                      ? null
                      : _submit,
                  child: state.status == UserStatus.loading
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          widget.isEditing
                              ? 'Guardar cambios'
                              : 'Crear usuario',
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Future<void> _selectBirthDate() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (selected != null && mounted) setState(() => _birthDate = selected);
  }

  String? _validateName(String? value, String field) =>
      value == null || value.trim().isEmpty ? 'Ingresa el $field' : null;

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
    return balance == null || balance < 0 ? 'Ingresa un saldo válido' : null;
  }

  String? _optional(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusManager.instance.primaryFocus?.unfocus();
    _submitted = true;
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final bloc = context.read<UserBloc>();
    final user = widget.user;
    if (user == null) {
      bloc.add(
        UserEvent.createRequested(
          widget.actorUserId,
          email: _emailController.text.trim(),
          firstName: firstName,
          lastName: lastName,
          birthDate: _birthDate,
          phone: _optional(_phoneController.text),
          initialBalanceCop: int.parse(_balanceController.text),
        ),
      );
      return;
    }
    bloc.add(
      UserEvent.updateRequested(
        widget.actorUserId,
        user.id,
        firstName: firstName,
        lastName: lastName,
        birthDate: _birthDate,
        phone: _optional(_phoneController.text),
      ),
    );
  }

  Future<void> _onStateChanged(BuildContext context, UserState state) async {
    if (!_submitted) return;
    if (state.status == UserStatus.failure) {
      _submitted = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing
                ? 'No pudimos actualizar el usuario'
                : 'No pudimos crear el usuario',
          ),
        ),
      );
      return;
    }
    if (widget.isEditing && state.status == UserStatus.updated) {
      Navigator.of(context).pop(true);
      return;
    }
    if (widget.isEditing || state.status != UserStatus.created) return;
    final issuer = widget.issueActivationCode;
    if (issuer == null) return;
    final createdUser = _createdUser(state.users);
    final code = await issuer(widget.actorUserId, createdUser.email);
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
    if (context.mounted) Navigator.of(context).pop(true);
  }

  UserProfile _createdUser(List<UserProfile> users) => users.lastWhere(
    (user) => user.email == _emailController.text.trim(),
    orElse: () => users.last,
  );
}
