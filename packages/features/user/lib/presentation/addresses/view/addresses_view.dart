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
    listenWhen: (previous, current) => previous != current,
    listener: _onStateChanged,
    child: ResponsiveBreakpoints.of(context).largerThan(MOBILE)
        ? AddressesWeb(actorUserId: actorUserId, userId: userId)
        : AddressesMobile(actorUserId: actorUserId, userId: userId),
  );

  void _onStateChanged(BuildContext context, AddressState state) {
    state.when<void>(
      initial: (_, _) {},
      loading: (_, _) {},
      loaded: (_, _) {},
      ready: (_, _) {},
      saving: (_, _) {},
      created: (_, _) {},
      updated: (_, _) {},
      primaryUpdated: (_, _) => AppNotification.showNotification(
        context,
        title: 'address.notifications.primary_updated'.tr(),
      ),
      deleted: (_, _) => AppNotification.showNotification(
        context,
        title: 'address.notifications.deleted'.tr(),
      ),
      loadFailure: (_, _, _) {},
      actionFailure: (message, _, _) =>
          AppNotification.showNotificationError(context, title: message),
    );
  }
}
