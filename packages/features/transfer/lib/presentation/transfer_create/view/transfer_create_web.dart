import 'package:feature_transfer/presentation/transfer/bloc/transfer_bloc.dart';
import 'package:feature_transfer/presentation/transfer/bloc/transfer_event.dart';
import 'package:feature_transfer/presentation/transfer/bloc/transfer_state.dart';
import 'package:feature_transfer/domain/entities/transfer_party.dart';
import 'package:feature_transfer/presentation/transfer_create/widgets/transfer_create_content.dart';
import 'package:feature_transfer/presentation/shared/widgets/transfer_load_failure.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TransferCreateWeb extends StatelessWidget {
  const TransferCreateWeb({
    required this.actorUserId,
    required this.isAdmin,
    super.key,
  });

  final int actorUserId;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<TransferBloc, TransferState>(
        builder: (context, state) => state.when(
          initial: (parties) => _loadingOrContent(context, parties),
          loading: (parties) => _loadingOrContent(context, parties),
          loaded: (parties) => _contentOrEmpty(context, parties),
          submitting: (parties) =>
              _content(context, parties: parties, isSubmitting: true),
          completed: (parties, _) =>
              _content(context, parties: parties, isSubmitting: false),
          failure: (message, parties) => parties.isEmpty
              ? TransferLoadFailure(
                  message: message,
                  onRetry: () => _reload(context),
                )
              : _content(context, parties: parties, isSubmitting: false),
        ),
      );

  Widget _loadingOrContent(BuildContext context, List<TransferParty> parties) =>
      parties.isEmpty
      ? const _Loading()
      : _content(context, parties: parties, isSubmitting: false);

  Widget _contentOrEmpty(BuildContext context, List<TransferParty> parties) =>
      parties.isEmpty
      ? TransferLoadFailure(
          message: 'transfer.form.no_users'.tr(),
          onRetry: () => _reload(context),
        )
      : _content(context, parties: parties, isSubmitting: false);

  Widget _content(
    BuildContext context, {
    required List<TransferParty> parties,
    required bool isSubmitting,
  }) => TransferCreateContent(
    key: const Key('transfer-create-content'),
    actorUserId: actorUserId,
    isAdmin: isAdmin,
    parties: parties,
    isSubmitting: isSubmitting,
    maxWidth: 760,
    onReload: () => _reload(context),
    onSubmit: (event) => context.read<TransferBloc>().add(event),
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
