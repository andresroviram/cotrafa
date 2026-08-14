import 'package:feature_user/domain/entities/user_profile.dart';
import 'package:feature_user/presentation/users/bloc/user_bloc.dart';
import 'package:feature_user/presentation/users/bloc/user_event.dart';
import 'package:feature_user/presentation/users/bloc/user_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class UserEditForm extends StatefulWidget {
  const UserEditForm({
    required this.actorUserId,
    required this.user,
    super.key,
  });

  final int actorUserId;
  final UserProfile user;

  @override
  State<UserEditForm> createState() => _UserEditFormState();
}

class _UserEditFormState extends State<UserEditForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late DateTime? _birthDate;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.user.firstName);
    _lastNameController = TextEditingController(text: widget.user.lastName);
    _phoneController = TextEditingController(text: widget.user.phone);
    _emailController = TextEditingController(text: widget.user.email);
    _birthDate = widget.user.birthDate;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
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
          16,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                key: const Key('edit-user-first-name'),
                controller: _firstNameController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('edit-user-last-name'),
                controller: _lastNameController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Apellido',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                key: const Key('edit-user-birth-date'),
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
                key: const Key('edit-user-phone'),
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('edit-user-email'),
                controller: _emailController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  prefixIcon: Icon(Icons.email_outlined),
                  helperText: 'El correo no se puede modificar',
                ),
              ),
              const SizedBox(height: 24),
              BlocBuilder<UserBloc, UserState>(
                buildWhen: (previous, current) =>
                    previous.status != current.status,
                builder: (context, state) => FilledButton(
                  key: const Key('edit-user-submit'),
                  onPressed: state.status == UserStatus.loading
                      ? null
                      : _submit,
                  child: state.status == UserStatus.loading
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Guardar cambios'),
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

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusManager.instance.primaryFocus?.unfocus();
    _submitted = true;
    context.read<UserBloc>().add(
      UserEvent.updateRequested(
        widget.actorUserId,
        widget.user.id,
        firstName: _optional(_firstNameController.text),
        lastName: _optional(_lastNameController.text),
        birthDate: _birthDate,
        phone: _optional(_phoneController.text),
      ),
    );
  }

  String? _optional(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  void _onStateChanged(BuildContext context, UserState state) {
    if (!_submitted) return;
    if (state.status == UserStatus.failure) {
      _submitted = false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos actualizar el usuario')),
      );
      return;
    }
    if (state.status == UserStatus.updated) Navigator.of(context).pop(true);
  }
}
