import 'package:components/localized_formatters.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feature_user/domain/entities/user_profile.dart';
import 'package:flutter/material.dart';

class UserCard extends StatelessWidget {
  const UserCard({
    super.key,
    required this.user,
    this.onTap,
    this.onEdit,
    this.onGenerateActivationCode,
    this.onDelete,
  });

  final UserProfile user;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onGenerateActivationCode;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Hero(
                      tag: 'user-avatar-${user.id}',
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Text(
                          user.initials,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _Label(text: _status(user.status)),
                              _Label(
                                text: localizedCop(context, user.balanceCop),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (onEdit != null ||
                onGenerateActivationCode != null ||
                onDelete != null)
              PopupMenuButton<_UserCardAction>(
                key: Key('user-actions-${user.id}'),
                tooltip: 'user.actions.tooltip'.tr(),
                offset: const Offset(0, 40),
                itemBuilder: (_) => [
                  if (onEdit != null)
                    PopupMenuItem(
                      key: Key('edit-user-${user.id}'),
                      value: _UserCardAction.edit,
                      onTap: onEdit,
                      child: _MenuItem(
                        icon: Icons.edit_outlined,
                        label: 'common.edit'.tr(),
                      ),
                    ),
                  if (onGenerateActivationCode != null)
                    PopupMenuItem(
                      key: Key('regenerate-code-${user.id}'),
                      value: _UserCardAction.regenerateCode,
                      onTap: onGenerateActivationCode,
                      child: _MenuItem(
                        icon: Icons.key_outlined,
                        label: 'user.actions.regenerate_code'.tr(),
                      ),
                    ),
                  if (onDelete != null)
                    PopupMenuItem(
                      key: Key('delete-user-${user.id}'),
                      value: _UserCardAction.delete,
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
      ),
    );
  }
}

enum _UserCardAction { edit, regenerateCode, delete }

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

String _status(String value) => switch (value) {
  'pendingActivation' => 'user.status.pending'.tr(),
  'active' => 'user.status.active'.tr(),
  'inactive' => 'user.status.inactive'.tr(),
  _ => value,
};

class _Label extends StatelessWidget {
  const _Label({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          text,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}
