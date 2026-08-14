import 'package:core/get_it.dart';
import 'package:core/utils/notifications.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feature_user/presentation/addresses/bloc/address_bloc.dart';
import 'package:feature_user/presentation/addresses/bloc/address_event.dart';
import 'package:feature_user/presentation/addresses/bloc/address_state.dart';
import 'package:feature_user/presentation/addresses/view/addresses_mobile.dart';
import 'package:feature_user/presentation/addresses/view/addresses_web.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_framework.dart';

class AddressesView extends StatelessWidget {
  const AddressesView({
    required this.actorUserId,
    required this.userId,
    super.key,
  });

  final int actorUserId;
  final int userId;

  static const String path = 'addresses';
  static const String name = 'user-addresses';

  static Widget create({required int actorUserId, required int userId}) =>
      BlocProvider(
        create: (_) =>
            getIt<AddressBloc>()
              ..add(AddressEvent.listRequested(actorUserId, userId)),
        child: AddressesView(actorUserId: actorUserId, userId: userId),
      );

  @override
  Widget build(BuildContext context) => BlocListener<AddressBloc, AddressState>(
    listenWhen: (previous, current) =>
        previous.status != current.status ||
        previous.message != current.message,
    listener: _onStateChanged,
    child: ResponsiveBreakpoints.of(context).largerThan(MOBILE)
        ? AddressesWeb(actorUserId: actorUserId, userId: userId)
        : AddressesMobile(actorUserId: actorUserId, userId: userId),
  );

  void _onStateChanged(BuildContext context, AddressState state) {
    if (state.status == AddressStatus.actionFailure && state.message != null) {
      AppNotification.showNotificationError(
        context,
        title: state.message!.tr(),
      );
      return;
    }
    final message = switch (state.status) {
      AddressStatus.primaryUpdated => 'address.notifications.primary_updated',
      AddressStatus.deleted => 'address.notifications.deleted',
      _ => null,
    };
    if (message != null) {
      AppNotification.showNotification(context, title: message.tr());
    }
  }
}
