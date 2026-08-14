import 'package:feature_transfer/presentation/transfer/bloc/transfer_bloc.dart';
import 'package:feature_transfer/presentation/transfer/bloc/transfer_event.dart';
import 'package:feature_transfer/presentation/transfer/bloc/transfer_state.dart';
import 'package:feature_transfer/presentation/transfer/bloc/transfer_state_x.dart';
import 'package:feature_transfer/presentation/transfer_create/widgets/transfer_create_content.dart';
import 'package:feature_transfer/presentation/shared/widgets/transfer_load_failure.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TransferCreateMobile extends StatelessWidget {
  const TransferCreateMobile({
    required this.actorUserId,
    required this.isAdmin,
    super.key,
  });

  final int actorUserId;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<TransferBloc, TransferState>(
        builder: (context, state) => state.resolve(
          loading: () => const _Loading(),
          failure: (message) => TransferLoadFailure(
            message: message,
            onRetry: () => _reload(context),
          ),
          empty: () => TransferLoadFailure(
            message: 'transfer.form.no_users',
            onRetry: () => _reload(context),
          ),
          data: (resolved) => TransferCreateContent(
            key: const Key('transfer-create-content'),
            actorUserId: actorUserId,
            isAdmin: isAdmin,
            state: resolved,
            maxWidth: 600,
            onReload: () => _reload(context),
            onSubmit: (event) => context.read<TransferBloc>().add(event),
          ),
        ),
      );

  void _reload(BuildContext context) => context.read<TransferBloc>().add(
    TransferEvent.loadRequested(actorUserId),
  );
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('transfer.new'.tr())),
    body: const Center(child: CircularProgressIndicator()),
  );
}
