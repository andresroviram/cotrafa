import 'dart:async';

import 'package:core/get_it.dart';
import 'package:core/utils/notifications.dart';
import 'package:feature_transfer/presentation/transfer/bloc/transfer_bloc.dart';
import 'package:feature_transfer/presentation/transfer/bloc/transfer_event.dart';
import 'package:feature_transfer/presentation/transfer/bloc/transfer_state.dart';
import 'package:feature_transfer/presentation/transfer_create/view/transfer_create_mobile.dart';
import 'package:feature_transfer/presentation/transfer_create/view/transfer_create_web.dart';
import 'package:feature_transfer/presentation/transfer_result/transfer_outcome.dart';
import 'package:feature_transfer/presentation/transfer_result/view/transfer_result_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';

class TransferCreateView extends StatelessWidget {
  const TransferCreateView({
    required this.actorUserId,
    required this.isAdmin,
    super.key,
  });

  final int actorUserId;
  final bool isAdmin;

  static const String path = 'new';
  static const String name = 'transfer-create';

  static Widget create({required int actorUserId, required bool isAdmin}) =>
      BlocProvider(
        create: (_) =>
            getIt<TransferBloc>()
              ..add(TransferEvent.loadRequested(actorUserId)),
        child: TransferCreateView(actorUserId: actorUserId, isAdmin: isAdmin),
      );

  @override
  Widget build(BuildContext context) =>
      BlocListener<TransferBloc, TransferState>(
        listenWhen: _shouldListen,
        listener: _onStateChanged,
        child: ResponsiveBreakpoints.of(context).largerThan(MOBILE)
            ? TransferCreateWeb(actorUserId: actorUserId, isAdmin: isAdmin)
            : TransferCreateMobile(actorUserId: actorUserId, isAdmin: isAdmin),
      );

  void _onStateChanged(BuildContext context, TransferState state) {
    if (!context.mounted) return;
    final outcome = state.when<TransferOutcome?>(
      initial: (_) => null,
      loading: (_) => null,
      loaded: (_) => null,
      submitting: (_) => null,
      completed: (_, receipt) => TransferOutcome.success(receipt),
      failure: (message, parties) =>
          parties.isEmpty ? null : TransferOutcome.failure(message),
    );
    if (outcome != null) {
      unawaited(_openResult(context, outcome));
    } else {
      state.when<void>(
        initial: (_) {},
        loading: (_) {},
        loaded: (_) {},
        submitting: (_) {},
        completed: (_, _) {},
        failure: (message, parties) {
          if (parties.isEmpty) {
            AppNotification.showNotificationError(context, title: message);
          }
        },
      );
    }
  }

  bool _shouldListen(TransferState previous, TransferState current) {
    final wasSubmitting = previous.when(
      initial: (_) => false,
      loading: (_) => false,
      loaded: (_) => false,
      submitting: (_) => true,
      completed: (_, _) => false,
      failure: (_, _) => false,
    );
    final isSubmissionResult = current.when(
      initial: (_) => false,
      loading: (_) => false,
      loaded: (_) => false,
      submitting: (_) => false,
      completed: (_, _) => true,
      failure: (_, _) => true,
    );
    final isInitialLoadFailure = current.when(
      initial: (_) => false,
      loading: (_) => false,
      loaded: (_) => false,
      submitting: (_) => false,
      completed: (_, _) => false,
      failure: (_, parties) => parties.isEmpty,
    );
    return wasSubmitting && isSubmissionResult || isInitialLoadFailure;
  }

  Future<void> _openResult(
    BuildContext context,
    TransferOutcome outcome,
  ) async {
    final returnToHistory = await context.pushNamed<bool>(
      TransferResultView.name,
      extra: outcome,
    );
    if (returnToHistory == true && context.mounted) context.pop(true);
  }
}
