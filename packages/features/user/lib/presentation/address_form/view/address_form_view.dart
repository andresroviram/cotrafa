import 'package:core/get_it.dart';
import 'package:core/utils/notifications.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feature_user/presentation/address_form/view/address_form_mobile.dart';
import 'package:feature_user/presentation/address_form/view/address_form_web.dart';
import 'package:feature_user/presentation/addresses/bloc/address_bloc.dart';
import 'package:feature_user/presentation/addresses/bloc/address_event.dart';
import 'package:feature_user/presentation/addresses/bloc/address_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_framework.dart';

class AddressFormView extends StatelessWidget {
  const AddressFormView({
    required this.actorUserId,
    required this.userId,
    this.addressId,
    super.key,
  });

  final int actorUserId;
  final int userId;
  final int? addressId;

  static const String createPath = 'new';
  static const String createName = 'create-address';
  static const String editPath = ':addressId/edit';
  static const String editName = 'edit-address';

  static Widget create({
    required int actorUserId,
    required int userId,
    int? addressId,
  }) => BlocProvider(
    create: (_) => getIt<AddressBloc>()
      ..add(
        AddressEvent.formRequested(actorUserId, userId, addressId: addressId),
      ),
    child: AddressFormView(
      actorUserId: actorUserId,
      userId: userId,
      addressId: addressId,
    ),
  );

  @override
  Widget build(BuildContext context) => BlocListener<AddressBloc, AddressState>(
    listenWhen: (previous, current) => previous != current,
    listener: _onStateChanged,
    child: ResponsiveBreakpoints.of(context).largerThan(MOBILE)
        ? AddressFormWeb(
            actorUserId: actorUserId,
            userId: userId,
            addressId: addressId,
          )
        : AddressFormMobile(
            actorUserId: actorUserId,
            userId: userId,
            addressId: addressId,
          ),
  );

  void _onStateChanged(BuildContext context, AddressState state) {
    state.when<void>(
      initial: (_, _) {},
      loading: (_, _) {},
      loaded: (_, _) {},
      ready: (_, _) {},
      saving: (_, _) {},
      created: (_, _) => _complete(context, 'address.notifications.created'),
      updated: (_, _) => _complete(context, 'address.notifications.updated'),
      primaryUpdated: (_, _) {},
      deleted: (_, _) {},
      loadFailure: (_, _, _) {},
      actionFailure: (message, _, _) =>
          AppNotification.showNotificationError(context, title: message),
    );
  }

  void _complete(BuildContext context, String messageKey) {
    AppNotification.showNotification(context, title: messageKey.tr());
    final navigator = Navigator.of(context);
    if (navigator.canPop()) navigator.pop(true);
  }
}
