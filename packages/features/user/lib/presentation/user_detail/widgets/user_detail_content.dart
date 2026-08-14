import 'package:components/localized_formatters.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feature_user/domain/entities/user_profile.dart';
import 'package:flutter/material.dart';

class UserDetailContent extends StatelessWidget {
  const UserDetailContent({
    required this.user,
    required this.onRefresh,
    required this.onEdit,
    required this.onAddresses,
    super.key,
  });

  final UserProfile user;
  final VoidCallback onRefresh;
  final VoidCallback onEdit;
  final VoidCallback onAddresses;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final appBarColor = theme.appBarTheme.backgroundColor ?? colors.primary;
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => onRefresh(),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: appBarColor,
              foregroundColor:
                  theme.appBarTheme.foregroundColor ?? colors.onPrimary,
              surfaceTintColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                background: DecoratedBox(
                  decoration: BoxDecoration(color: appBarColor),
                  child: Center(
                    child: Hero(
                      tag: 'user-avatar-${user.id}',
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: colors.surface,
                        child: Text(
                          user.initials,
                          style: theme.textTheme.displaySmall?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      user.displayName,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _BalanceCard(balanceCop: user.balanceCop),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: onEdit,
                            icon: const Icon(Icons.edit_outlined),
                            label: Text('common.edit'.tr()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: onAddresses,
                            icon: const Icon(Icons.location_on_outlined),
                            label: Text('user.detail.addresses'.tr()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _SectionHeader(
                      icon: Icons.person_outline,
                      title: 'user.detail.personal_information'.tr(),
                    ),
                    const SizedBox(height: 16),
                    _InfoCard(
                      items: [
                        _InfoItem(
                          icon: Icons.badge_outlined,
                          label: 'user.detail.first_name'.tr(),
                          value: _optional(context, user.firstName),
                        ),
                        _InfoItem(
                          icon: Icons.badge,
                          label: 'user.detail.last_name'.tr(),
                          value: _optional(context, user.lastName),
                        ),
                        _InfoItem(
                          icon: Icons.cake_outlined,
                          label: 'user.detail.birth_date'.tr(),
                          value: user.birthDate == null
                              ? 'common.not_registered'.tr()
                              : localizedDate(context, user.birthDate!),
                        ),
                        _InfoItem(
                          icon: Icons.calendar_today_outlined,
                          label: 'user.detail.age'.tr(),
                          value: switch (user.ageAt(DateTime.now())) {
                            final age? => 'user.detail.age_value'.tr(
                              namedArgs: {'age': '$age'},
                            ),
                            null => 'common.not_registered'.tr(),
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _SectionHeader(
                      icon: Icons.contact_mail_outlined,
                      title: 'user.detail.contact'.tr(),
                    ),
                    const SizedBox(height: 16),
                    _InfoCard(
                      items: [
                        _InfoItem(
                          icon: Icons.email_outlined,
                          label: 'user.detail.email'.tr(),
                          value: user.email,
                        ),
                        _InfoItem(
                          icon: Icons.phone_outlined,
                          label: 'user.detail.phone'.tr(),
                          value: _formatPhone(context, user.phone),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balanceCop});

  final int balanceCop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      key: const Key('user-available-balance'),
      margin: EdgeInsets.zero,
      color: colors.primaryContainer,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.account_balance_wallet_outlined, color: colors.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'user.detail.available_balance'.tr(),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    localizedCop(context, balanceCop),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.items});

  final List<_InfoItem> items;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            _InfoItemRow(item: items[index]),
            if (index < items.length - 1) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
            ],
          ],
        ],
      ),
    ),
  );
}

class _InfoItem {
  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _InfoItemRow extends StatelessWidget {
  const _InfoItemRow({required this.item});

  final _InfoItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(item.icon, size: 20, color: colors.primary),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _optional(BuildContext context, String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty
      ? 'common.not_registered'.tr()
      : normalized;
}

String _formatPhone(BuildContext context, String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) {
    return 'common.not_registered'.tr();
  }
  final digits = normalized.replaceAll(RegExp(r'\D'), '');
  if (digits.length != 10) return normalized;
  return '${digits.substring(0, 3)} ${digits.substring(3, 6)} '
      '${digits.substring(6)}';
}
