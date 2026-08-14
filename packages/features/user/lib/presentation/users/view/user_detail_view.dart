import 'package:core/get_it.dart';
import 'package:feature_user/domain/entities/user_profile.dart';
import 'package:feature_user/presentation/users/bloc/user_bloc.dart';
import 'package:feature_user/presentation/users/bloc/user_event.dart';
import 'package:feature_user/presentation/users/bloc/user_state.dart';
import 'package:feature_user/presentation/users/widgets/user_form_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class UserDetailView extends StatelessWidget {
  const UserDetailView({
    required this.actorUserId,
    required this.userId,
    super.key,
  });

  final int actorUserId;
  final int userId;

  static const String path = ':userId';
  static const String name = 'user-detail';

  static Widget create({required int actorUserId, required int userId}) =>
      BlocProvider(
        create: (_) =>
            getIt<UserBloc>()
              ..add(UserEvent.profileRequested(actorUserId, userId)),
        child: UserDetailView(actorUserId: actorUserId, userId: userId),
      );

  @override
  Widget build(BuildContext context) => BlocBuilder<UserBloc, UserState>(
    builder: (context, state) {
      final user = _findUser(state.users);
      if (user != null) {
        return _UserDetailContent(
          user: user,
          onRefresh: () => _reload(context),
          onEdit: () => _edit(context, user),
        );
      }
      if (state.status == UserStatus.failure) {
        return Scaffold(
          appBar: AppBar(),
          body: _LoadFailure(onRetry: () => _reload(context)),
        );
      }
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    },
  );

  UserProfile? _findUser(List<UserProfile> users) {
    for (final user in users) {
      if (user.id == userId) return user;
    }
    return null;
  }

  void _reload(BuildContext context) => context.read<UserBloc>().add(
    UserEvent.profileRequested(actorUserId, userId),
  );

  Future<void> _edit(BuildContext context, UserProfile user) async {
    final updated = await showUserFormModal(
      context,
      actorUserId: actorUserId,
      user: user,
    );
    if (updated == true && context.mounted) _reload(context);
  }
}

class _UserDetailContent extends StatelessWidget {
  const _UserDetailContent({
    required this.user,
    required this.onRefresh,
    required this.onEdit,
  });

  final UserProfile user;
  final VoidCallback onRefresh;
  final VoidCallback onEdit;

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
                            label: const Text('Editar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: () => _addressesComingSoon(context),
                            icon: const Icon(Icons.location_on_outlined),
                            label: const Text('Direcciones'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    const _SectionHeader(
                      icon: Icons.person_outline,
                      title: 'Información personal',
                    ),
                    const SizedBox(height: 16),
                    _InfoCard(
                      items: [
                        _InfoItem(
                          icon: Icons.badge_outlined,
                          label: 'Nombre',
                          value: _optional(user.firstName),
                        ),
                        _InfoItem(
                          icon: Icons.badge,
                          label: 'Apellido',
                          value: _optional(user.lastName),
                        ),
                        _InfoItem(
                          icon: Icons.cake_outlined,
                          label: 'Fecha de nacimiento',
                          value: user.birthDate == null
                              ? 'Sin registrar'
                              : DateFormat(
                                  'dd/MM/yyyy',
                                ).format(user.birthDate!),
                        ),
                        _InfoItem(
                          icon: Icons.calendar_today_outlined,
                          label: 'Edad',
                          value: switch (user.ageAt(DateTime.now())) {
                            final age? => '$age años',
                            null => 'Sin registrar',
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const _SectionHeader(
                      icon: Icons.contact_mail_outlined,
                      title: 'Contacto',
                    ),
                    const SizedBox(height: 16),
                    _InfoCard(
                      items: [
                        _InfoItem(
                          icon: Icons.email_outlined,
                          label: 'Correo electrónico',
                          value: user.email,
                        ),
                        _InfoItem(
                          icon: Icons.phone_outlined,
                          label: 'Teléfono',
                          value: _formatPhone(user.phone),
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

  void _addressesComingSoon(BuildContext context) =>
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La gestión de direcciones estará disponible próximamente',
          ),
        ),
      );
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
                    'Saldo disponible',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _currency.format(balanceCop),
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

class _LoadFailure extends StatelessWidget {
  const _LoadFailure({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('No pudimos cargar el usuario'),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
      ],
    ),
  );
}

String _optional(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty
      ? 'Sin registrar'
      : normalized;
}

String _formatPhone(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) return 'Sin registrar';
  final digits = normalized.replaceAll(RegExp(r'\D'), '');
  if (digits.length != 10) return normalized;
  return '${digits.substring(0, 3)} ${digits.substring(3, 6)} '
      '${digits.substring(6)}';
}

final NumberFormat _currency = NumberFormat.currency(
  locale: 'es_CO',
  symbol: r'$',
  decimalDigits: 0,
);
