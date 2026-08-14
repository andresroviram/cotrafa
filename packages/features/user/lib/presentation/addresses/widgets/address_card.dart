import 'package:easy_localization/easy_localization.dart';
import 'package:feature_user/domain/entities/user_address.dart';
import 'package:flutter/material.dart';

class AddressCard extends StatelessWidget {
  const AddressCard({
    required this.address,
    required this.onEdit,
    required this.onSetPrimary,
    required this.onDelete,
    super.key,
  });

  final UserAddress address;
  final VoidCallback onEdit;
  final VoidCallback onSetPrimary;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      key: Key('address-card-${address.id}'),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.only(left: 16, top: 16, bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _labelIcon(address.label),
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Text(
                          _localizedLabel(address.label),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (address.isPrimary) const _PrimaryLabel(),
                      ],
                    ),
                  ),
                  PopupMenuButton<_AddressAction>(
                    key: Key('address-actions-${address.id}'),
                    tooltip: 'address.actions_tooltip'.tr(),
                    offset: const Offset(0, 40),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: _AddressAction.edit,
                        onTap: onEdit,
                        child: _MenuItem(
                          icon: Icons.edit_outlined,
                          label: 'common.edit'.tr(),
                        ),
                      ),
                      if (!address.isPrimary)
                        PopupMenuItem(
                          value: _AddressAction.primary,
                          onTap: onSetPrimary,
                          child: _MenuItem(
                            icon: Icons.star_outline,
                            label: 'address.set_primary'.tr(),
                          ),
                        ),
                      PopupMenuItem(
                        value: _AddressAction.delete,
                        onTap: onDelete,
                        child: _MenuItem(
                          icon: Icons.delete_outline,
                          label: 'common.delete'.tr(),
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      address.line1,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (address.line2 case final line2?) ...[
                      const SizedBox(height: 4),
                      Text(line2, style: _secondaryStyle(theme)),
                    ],
                    const SizedBox(height: 4),
                    Text(address.location, style: _secondaryStyle(theme)),
                    if (address.postalCode case final postalCode?) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.markunread_mailbox_outlined,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'address.postal_code_short'.tr(
                              namedArgs: {'code': postalCode},
                            ),
                            style: _secondaryStyle(theme),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle? _secondaryStyle(ThemeData theme) => theme.textTheme.bodyMedium
      ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
}

enum _AddressAction { edit, primary, delete }

class _PrimaryLabel extends StatelessWidget {
  const _PrimaryLabel();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        child: Text(
          'address.primary'.tr(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colors.onPrimaryContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: color),
      const SizedBox(width: 12),
      Flexible(
        child: Text(label, style: TextStyle(color: color)),
      ),
    ],
  );
}

IconData _labelIcon(String label) => switch (label.trim().toLowerCase()) {
  'casa' || 'home' => Icons.home_outlined,
  'trabajo' || 'work' => Icons.work_outline,
  _ => Icons.location_on_outlined,
};

String _localizedLabel(String label) => switch (label.trim().toLowerCase()) {
  'casa' || 'home' => 'address.types.home'.tr(),
  'trabajo' || 'work' => 'address.types.work'.tr(),
  'otra' || 'other' => 'address.types.other'.tr(),
  _ => label,
};
