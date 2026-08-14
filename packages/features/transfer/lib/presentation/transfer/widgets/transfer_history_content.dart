import 'package:components/localized_formatters.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feature_transfer/domain/entities/transfer_receipt.dart';
import 'package:flutter/material.dart';

class TransferHistoryContent extends StatelessWidget {
  const TransferHistoryContent({
    required this.actorUserId,
    required this.transfers,
    required this.maxWidth,
    required this.onReload,
    required this.onCreate,
    super.key,
  });

  final int actorUserId;
  final List<TransferReceipt> transfers;
  final double maxWidth;
  final Future<void> Function() onReload;
  final Future<void> Function() onCreate;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('transfer.title'.tr())),
    floatingActionButton: FloatingActionButton.extended(
      key: const Key('transfer-create-fab'),
      onPressed: onCreate,
      icon: const Icon(Icons.add),
      label: Text('transfer.action'.tr()),
    ),
    body: SafeArea(
      child: RefreshIndicator(
        onRefresh: onReload,
        child: transfers.isEmpty ? _empty(context) : _history(context),
      ),
    ),
  );

  Widget _empty(BuildContext context) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.all(24),
    children: [
      SizedBox(height: MediaQuery.sizeOf(context).height * 0.2),
      Icon(
        Icons.receipt_long_outlined,
        size: 56,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      const SizedBox(height: 16),
      Text(
        'transfer.empty'.tr(),
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 8),
      Text(
        'transfer.empty_description'.tr(),
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );

  Widget _history(BuildContext context) => ListView.separated(
    key: const Key('transfer-history-list'),
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(24, 24, 24, 104),
    itemCount: transfers.length,
    separatorBuilder: (_, _) => const SizedBox(height: 12),
    itemBuilder: (context, index) => Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: _TransferHistoryCard(
          actorUserId: actorUserId,
          transfer: transfers[index],
        ),
      ),
    ),
  );
}

class _TransferHistoryCard extends StatelessWidget {
  const _TransferHistoryCard({
    required this.actorUserId,
    required this.transfer,
  });

  final int actorUserId;
  final TransferReceipt transfer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final outgoing = transfer.originUserId == actorUserId;
    final incoming = transfer.destinationUserId == actorUserId;
    final label = outgoing
        ? 'transfer.history.sent'.tr()
        : incoming
        ? 'transfer.history.received'.tr()
        : 'transfer.history.default'.tr();
    final sign = outgoing
        ? '- '
        : incoming
        ? '+ '
        : '';
    final color = outgoing
        ? theme.colorScheme.error
        : incoming
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface;
    return Card(
      key: Key('transfer-card-${transfer.id}'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              foregroundColor: color,
              child: Icon(
                outgoing
                    ? Icons.north_east
                    : incoming
                    ? Icons.south_west
                    : Icons.swap_horiz,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        '$sign${localizedCop(context, transfer.amountCop)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${transfer.originSnapshot} → '
                    '${transfer.destinationSnapshot}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (transfer.description case final description?) ...[
                    const SizedBox(height: 6),
                    Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    localizedDateTime(
                      context,
                      DateTime.fromMillisecondsSinceEpoch(transfer.createdAt),
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
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
