import 'package:feature_transfer/domain/entities/transfer_party.dart';
import 'package:feature_transfer/presentation/transfer/bloc/transfer_event.dart';
import 'package:feature_transfer/presentation/transfer/bloc/transfer_state.dart';
import 'package:feature_transfer/presentation/transfer/bloc/transfer_state_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

typedef TransferSubmit = void Function(TransferEvent event);

class TransferCreateContent extends StatefulWidget {
  const TransferCreateContent({
    required this.actorUserId,
    required this.isAdmin,
    required this.state,
    required this.maxWidth,
    required this.onReload,
    required this.onSubmit,
    super.key,
  });

  final int actorUserId;
  final bool isAdmin;
  final TransferState state;
  final double maxWidth;
  final VoidCallback onReload;
  final TransferSubmit onSubmit;

  @override
  State<TransferCreateContent> createState() => _TransferCreateContentState();
}

class _TransferCreateContentState extends State<TransferCreateContent> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  int? _originId;
  int? _destinationId;

  static final _currency = NumberFormat.currency(
    locale: 'es_CO',
    symbol: r'$',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _originId = _initialOriginId();
  }

  @override
  void didUpdateWidget(covariant TransferCreateContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_hasParty(_originId)) _originId = _initialOriginId();
    if (!_hasParty(_destinationId) || _destinationId == _originId) {
      _destinationId = null;
    }
    final previousReceipt = oldWidget.state.receipt;
    final currentReceipt = widget.state.receipt;
    if (currentReceipt != null && currentReceipt.id != previousReceipt?.id) {
      _amountController.clear();
      _descriptionController.clear();
      _destinationId = null;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Nueva transferencia')),
    body: SafeArea(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: RefreshIndicator(
          onRefresh: () async => widget.onReload(),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: widget.maxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _transferForm(context),
                    const SizedBox(height: 64),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _transferForm(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Nueva transferencia',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            if (widget.isAdmin)
              DropdownButtonFormField<int>(
                key: ValueKey('transfer-origin-$_originId'),
                initialValue: _originId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Usuario origen',
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                ),
                items: widget.state.parties
                    .map(
                      (party) => DropdownMenuItem(
                        value: party.id,
                        child: Text(_partyLabel(party)),
                      ),
                    )
                    .toList(),
                onChanged: widget.state.isSubmitting
                    ? null
                    : (value) => setState(() {
                        _originId = value;
                        if (_destinationId == value) _destinationId = null;
                      }),
                validator: (value) =>
                    value == null ? 'Selecciona el usuario origen.' : null,
              )
            else
              InputDecorator(
                key: const Key('transfer-client-origin'),
                decoration: const InputDecoration(
                  labelText: 'Usuario origen',
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                ),
                child: Text(switch (_party(_originId)) {
                  final party? => _partyLabel(party),
                  null => 'Usuario no disponible',
                }),
              ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              key: ValueKey('transfer-destination-$_destinationId-$_originId'),
              initialValue: _destinationId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Usuario destino',
                prefixIcon: Icon(Icons.person_outline),
              ),
              items: widget.state.parties
                  .where((party) => party.id != _originId)
                  .map(
                    (party) => DropdownMenuItem(
                      value: party.id,
                      child: Text(_partyLabel(party)),
                    ),
                  )
                  .toList(),
              onChanged: widget.state.isSubmitting
                  ? null
                  : (value) => setState(() => _destinationId = value),
              validator: (value) =>
                  value == null ? 'Selecciona el usuario destino.' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('transfer-amount'),
              controller: _amountController,
              enabled: !widget.state.isSubmitting,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Valor',
                prefixText: r'$ ',
              ),
              validator: _validateAmount,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('transfer-description'),
              controller: _descriptionController,
              enabled: !widget.state.isSubmitting,
              textInputAction: TextInputAction.done,
              maxLength: 160,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              key: const Key('transfer-submit'),
              onPressed: widget.state.isSubmitting ? null : _submit,
              icon: widget.state.isSubmitting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_outlined),
              label: const Text('Transferir'),
            ),
          ],
        ),
      ),
    ),
  );

  String? _validateAmount(String? value) {
    final amount = int.tryParse(value ?? '');
    if (amount == null || amount <= 0) return 'Ingresa un valor válido.';
    final origin = _party(_originId);
    if (origin != null && amount > origin.balanceCop) {
      return 'Saldo insuficiente.';
    }
    return null;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final originId = _originId;
    final destinationId = _destinationId;
    final amount = int.tryParse(_amountController.text);
    if (originId == null || destinationId == null || amount == null) return;
    FocusManager.instance.primaryFocus?.unfocus();
    widget.onSubmit(
      TransferEvent.createRequested(
        actorUserId: widget.actorUserId,
        originUserId: originId,
        destinationUserId: destinationId,
        amountCop: amount,
        description: _descriptionController.text,
      ),
    );
  }

  int? _initialOriginId() => widget.isAdmin
      ? null
      : _hasParty(widget.actorUserId)
      ? widget.actorUserId
      : null;

  bool _hasParty(int? id) => _party(id) != null;

  TransferParty? _party(int? id) {
    if (id == null) return null;
    for (final party in widget.state.parties) {
      if (party.id == id) return party;
    }
    return null;
  }

  String _partyLabel(TransferParty party) =>
      '${party.displayName} · ${_currency.format(party.balanceCop)}';
}
