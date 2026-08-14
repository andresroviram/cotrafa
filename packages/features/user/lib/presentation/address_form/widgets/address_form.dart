import 'package:easy_localization/easy_localization.dart';
import 'package:feature_user/domain/entities/user_address.dart';
import 'package:feature_user/presentation/addresses/bloc/address_bloc.dart';
import 'package:feature_user/presentation/addresses/bloc/address_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddressForm extends StatefulWidget {
  const AddressForm({
    required this.actorUserId,
    required this.userId,
    required this.address,
    required this.isSaving,
    super.key,
  });

  final int actorUserId;
  final int userId;
  final UserAddress? address;
  final bool isSaving;

  @override
  State<AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<AddressForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _line1Controller;
  late final TextEditingController _line2Controller;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _postalCodeController;
  late final TextEditingController _countryController;
  late String _label;

  @override
  void initState() {
    super.initState();
    final address = widget.address;
    _line1Controller = TextEditingController(text: address?.line1);
    _line2Controller = TextEditingController(text: address?.line2);
    _cityController = TextEditingController(text: address?.city);
    _stateController = TextEditingController(text: address?.state);
    _postalCodeController = TextEditingController(text: address?.postalCode);
    _countryController = TextEditingController(
      text: address?.country ?? 'address.default_country'.tr(),
    );
    _label = _supportedLabel(address?.label);
  }

  @override
  void dispose() {
    _line1Controller.dispose();
    _line2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.translucent,
    onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
    child: SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              key: const Key('address-label'),
              initialValue: _label,
              decoration: InputDecoration(
                labelText: 'address.type'.tr(),
                prefixIcon: const Icon(Icons.label_outline),
              ),
              items: [
                DropdownMenuItem(
                  value: 'Casa',
                  child: Text('address.types.home'.tr()),
                ),
                DropdownMenuItem(
                  value: 'Trabajo',
                  child: Text('address.types.work'.tr()),
                ),
                DropdownMenuItem(
                  value: 'Otra',
                  child: Text('address.types.other'.tr()),
                ),
              ],
              onChanged: widget.isSaving
                  ? null
                  : (value) => setState(() => _label = value ?? 'Casa'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('address-line-1'),
              controller: _line1Controller,
              enabled: !widget.isSaving,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'address.line1'.tr(),
                hintText: 'address.line1_hint'.tr(),
                prefixIcon: const Icon(Icons.home_outlined),
              ),
              validator: (value) => _required(value, 'address.line1_required'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('address-line-2'),
              controller: _line2Controller,
              enabled: !widget.isSaving,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'address.line2'.tr(),
                prefixIcon: const Icon(Icons.location_city_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('address-city'),
              controller: _cityController,
              enabled: !widget.isSaving,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'address.city'.tr(),
                prefixIcon: const Icon(Icons.location_city),
              ),
              validator: (value) => _required(value, 'address.city_required'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('address-state'),
              controller: _stateController,
              enabled: !widget.isSaving,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'address.state'.tr(),
                prefixIcon: const Icon(Icons.map_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('address-postal-code'),
              controller: _postalCodeController,
              enabled: !widget.isSaving,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'address.postal_code'.tr(),
                prefixIcon: const Icon(Icons.markunread_mailbox_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('address-country'),
              controller: _countryController,
              enabled: !widget.isSaving,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'address.country'.tr(),
                prefixIcon: const Icon(Icons.public),
              ),
              validator: (value) =>
                  _required(value, 'address.country_required'),
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('address-submit'),
              onPressed: widget.isSaving ? null : _submit,
              child: widget.isSaving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      widget.address == null
                          ? 'address.create'.tr()
                          : 'address.save'.tr(),
                    ),
            ),
          ],
        ),
      ),
    ),
  );

  String? _required(String? value, String messageKey) =>
      value == null || value.trim().isEmpty ? messageKey.tr() : null;

  String? _optional(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  String _supportedLabel(String? value) => switch (value?.toLowerCase()) {
    'trabajo' || 'work' => 'Trabajo',
    'otra' || 'other' => 'Otra',
    _ => 'Casa',
  };

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final draft = AddressDraft(
      line1: _line1Controller.text.trim(),
      line2: _optional(_line2Controller.text),
      city: _cityController.text.trim(),
      state: _optional(_stateController.text),
      postalCode: _optional(_postalCodeController.text),
      country: _countryController.text.trim(),
      label: _label,
    );
    final bloc = context.read<AddressBloc>();
    final address = widget.address;
    bloc.add(
      address == null
          ? AddressEvent.createRequested(
              widget.actorUserId,
              widget.userId,
              draft,
            )
          : AddressEvent.updateRequested(
              widget.actorUserId,
              widget.userId,
              address.id,
              draft,
            ),
    );
  }
}
