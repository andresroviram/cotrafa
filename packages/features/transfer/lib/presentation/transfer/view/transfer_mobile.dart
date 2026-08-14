import 'package:feature_transfer/presentation/transfer/bloc/transfer_history_bloc.dart';
import 'package:feature_transfer/presentation/transfer/bloc/transfer_history_event.dart';
import 'package:feature_transfer/presentation/transfer/bloc/transfer_history_state.dart';
import 'package:feature_transfer/presentation/transfer/bloc/transfer_history_state_x.dart';
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
        builder: (context, state) => state.resolve(
          loading: () => const _Loading(),
          failure: (message) => TransferLoadFailure(
            message: message,
            onRetry: () => _reload(context),
          ),
          empty: () => _content(context, state),
          data: (resolved) => _content(context, resolved),
        ),
      );

  Widget _content(BuildContext context, TransferHistoryState state) =>
      TransferHistoryContent(
        actorUserId: actorUserId,
        transfers: state.transfers,
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
