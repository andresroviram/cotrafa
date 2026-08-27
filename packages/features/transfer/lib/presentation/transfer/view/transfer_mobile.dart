import 'package:feature_transfer/domain/entities/transfer_receipt.dart';
import 'package:feature_transfer/presentation/transfer/bloc/transfer_history_bloc.dart';
import 'package:feature_transfer/presentation/transfer/bloc/transfer_history_event.dart';
import 'package:feature_transfer/presentation/transfer/bloc/transfer_history_state.dart';
import 'package:feature_transfer/presentation/transfer_create/view/transfer_create_view.dart';
import 'package:feature_transfer/presentation/transfer/widgets/transfer_history_content.dart';
import 'package:feature_transfer/presentation/shared/widgets/transfer_load_failure.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class TransferMobile extends StatelessWidget {
  const TransferMobile({required this.actorUserId, super.key});

  final int actorUserId;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<TransferHistoryBloc, TransferHistoryState>(
        builder: (context, state) => state.when(
          initial: () => const _Loading(),
          loading: () => const _Loading(),
          loaded: (transfers) => _content(context, transfers),
          failure: (message) => TransferLoadFailure(
            message: message,
            onRetry: () => _reload(context),
          ),
        ),
      );

  Widget _content(BuildContext context, List<TransferReceipt> transfers) =>
      TransferHistoryContent(
        actorUserId: actorUserId,
        transfers: transfers,
        maxWidth: 600,
        onReload: () async => _reload(context),
        onCreate: () => _create(context),
      );

  Future<void> _create(BuildContext context) async {
    await context.pushNamed<bool>(TransferCreateView.name);
    if (context.mounted) _reload(context);
  }

  void _reload(BuildContext context) => context.read<TransferHistoryBloc>().add(
    TransferHistoryEvent.loadRequested(actorUserId),
  );
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('transfer.title'.tr())),
    body: const Center(child: CircularProgressIndicator()),
  );
}
