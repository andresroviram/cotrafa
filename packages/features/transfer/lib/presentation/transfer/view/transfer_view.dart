import 'package:core/get_it.dart';
import 'package:core/utils/notifications.dart';
import 'package:feature_transfer/presentation/transfer/bloc/transfer_bloc.dart';
import 'package:feature_transfer/presentation/transfer/bloc/transfer_event.dart';
import 'package:feature_transfer/presentation/transfer/bloc/transfer_state.dart';
import 'package:feature_transfer/presentation/transfer/view/transfer_mobile.dart';
import 'package:feature_transfer/presentation/transfer/view/transfer_web.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_framework.dart';

class TransferView extends StatelessWidget {
  const TransferView({
    required this.actorUserId,
    required this.isAdmin,
    super.key,
  });

  final int actorUserId;
  final bool isAdmin;

  static const String path = '/transfer';
  static const String name = 'transfer';

  static Widget create({required int actorUserId, required bool isAdmin}) =>
      BlocProvider(
        create: (_) =>
            getIt<TransferBloc>()
              ..add(TransferEvent.loadRequested(actorUserId)),
        child: TransferView(actorUserId: actorUserId, isAdmin: isAdmin),
      );

  @override
  Widget build(BuildContext context) =>
      BlocListener<TransferBloc, TransferState>(
        listenWhen: (previous, current) =>
            previous.status != current.status ||
            previous.message != current.message,
        listener: _onStateChanged,
        child: ResponsiveBreakpoints.of(context).largerThan(MOBILE)
            ? TransferWeb(actorUserId: actorUserId, isAdmin: isAdmin)
            : TransferMobile(actorUserId: actorUserId, isAdmin: isAdmin),
      );

  void _onStateChanged(BuildContext context, TransferState state) {
    if (!context.mounted) return;
    if (state.status == TransferStatus.failure && state.message != null) {
      AppNotification.showNotificationError(context, title: state.message!);
    } else if (state.status == TransferStatus.completed) {
      AppNotification.showNotification(
        context,
        title: 'Transferencia realizada',
      );
    }
  }
}
