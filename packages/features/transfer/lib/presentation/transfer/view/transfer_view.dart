import 'package:core/get_it.dart';
import 'package:core/utils/notifications.dart';
import 'package:feature_transfer/presentation/transfer/bloc/transfer_history_bloc.dart';
import 'package:feature_transfer/presentation/transfer/bloc/transfer_history_event.dart';
import 'package:feature_transfer/presentation/transfer/bloc/transfer_history_state.dart';
import 'package:feature_transfer/presentation/transfer/view/transfer_mobile.dart';
import 'package:feature_transfer/presentation/transfer/view/transfer_web.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_framework.dart';

class TransferView extends StatelessWidget {
  const TransferView({required this.actorUserId, super.key});

  final int actorUserId;

  static const String path = '/transfer';
  static const String name = 'transfer';

  static Widget create({required int actorUserId}) => BlocProvider(
    create: (_) =>
        getIt<TransferHistoryBloc>()
          ..add(TransferHistoryEvent.loadRequested(actorUserId)),
    child: TransferView(actorUserId: actorUserId),
  );

  @override
  Widget build(BuildContext context) =>
      BlocListener<TransferHistoryBloc, TransferHistoryState>(
        listenWhen: (previous, current) =>
            previous.status != current.status ||
            previous.message != current.message,
        listener: _onStateChanged,
        child: ResponsiveBreakpoints.of(context).largerThan(MOBILE)
            ? TransferWeb(actorUserId: actorUserId)
            : TransferMobile(actorUserId: actorUserId),
      );

  void _onStateChanged(BuildContext context, TransferHistoryState state) {
    if (!context.mounted) return;
    if (state.status == TransferHistoryStatus.failure &&
        state.message != null) {
      AppNotification.showNotificationError(context, title: state.message!);
    }
  }
}
