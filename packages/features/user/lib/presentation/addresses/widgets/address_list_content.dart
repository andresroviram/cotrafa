import 'package:feature_user/domain/entities/user_address.dart';
import 'package:feature_user/presentation/addresses/widgets/address_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class AddressListContent extends StatelessWidget {
  const AddressListContent.loading({required this.onRefresh, super.key})
    : addresses = null,
      onRetry = null,
      onEdit = null,
      onSetPrimary = null,
      onDelete = null,
      _mode = _AddressListMode.loading;

  const AddressListContent.failure({
    required this.onRefresh,
    required this.onRetry,
    super.key,
  }) : addresses = null,
       onEdit = null,
       onSetPrimary = null,
       onDelete = null,
       _mode = _AddressListMode.failure;

  const AddressListContent.empty({required this.onRefresh, super.key})
    : addresses = null,
      onRetry = null,
      onEdit = null,
      onSetPrimary = null,
      onDelete = null,
      _mode = _AddressListMode.empty;

  const AddressListContent.data({
    required List<UserAddress> this.addresses,
    required this.onRefresh,
    required ValueChanged<UserAddress> this.onEdit,
    required ValueChanged<UserAddress> this.onSetPrimary,
    required ValueChanged<UserAddress> this.onDelete,
    super.key,
  }) : onRetry = null,
       _mode = _AddressListMode.data;

  final List<UserAddress>? addresses;
  final Future<void> Function() onRefresh;
  final VoidCallback? onRetry;
  final ValueChanged<UserAddress>? onEdit;
  final ValueChanged<UserAddress>? onSetPrimary;
  final ValueChanged<UserAddress>? onDelete;
  final _AddressListMode _mode;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.translucent,
    onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
    child: RefreshIndicator(onRefresh: onRefresh, child: _body()),
  );

  Widget _body() => switch (_mode) {
    _AddressListMode.loading => _static(
      const Center(child: CircularProgressIndicator()),
    ),
    _AddressListMode.failure => _static(_AddressFailure(onRetry: onRetry!)),
    _AddressListMode.empty => _static(const _EmptyAddresses()),
    _AddressListMode.data => ListView.separated(
      key: const Key('address-list'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: addresses!.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, index) {
        final address = addresses![index];
        return AddressCard(
          address: address,
          onEdit: () => onEdit!(address),
          onSetPrimary: () => onSetPrimary!(address),
          onDelete: () => onDelete!(address),
        );
      },
    ),
  };

  Widget _static(Widget child) => CustomScrollView(
    physics: const AlwaysScrollableScrollPhysics(),
    slivers: [SliverFillRemaining(hasScrollBody: false, child: child)],
  );
}

enum _AddressListMode { loading, failure, empty, data }

class _EmptyAddresses extends StatelessWidget {
  const _EmptyAddresses();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.location_off_outlined,
          size: 56,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 16),
        Text(
          'address.empty'.tr(),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        Text('address.empty_action'.tr()),
      ],
    ),
  );
}

class _AddressFailure extends StatelessWidget {
  const _AddressFailure({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, size: 52),
        const SizedBox(height: 12),
        Text('address.load_error'.tr()),
        const SizedBox(height: 16),
        FilledButton(onPressed: onRetry, child: Text('common.retry'.tr())),
      ],
    ),
  );
}
