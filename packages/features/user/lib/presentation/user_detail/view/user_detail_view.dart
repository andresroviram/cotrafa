import 'package:core/get_it.dart';
import 'package:core/utils/notifications.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feature_user/presentation/users/bloc/user_bloc.dart';
import 'package:feature_user/presentation/users/bloc/user_event.dart';
import 'package:feature_user/presentation/users/bloc/user_state.dart';
import 'package:feature_user/presentation/user_detail/view/user_detail_mobile.dart';
import 'package:feature_user/presentation/user_detail/view/user_detail_web.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_framework.dart';

class UserDetailView extends StatelessWidget {
  const UserDetailView({
    required this.actorUserId,
    required this.userId,
    super.key,
  });

  final int actorUserId;
  final int userId;

  static const String path = ':userId';
  static const String name = 'user-detail';

  static Widget create({required int actorUserId, required int userId}) =>
      BlocProvider(
        create: (_) =>
            getIt<UserBloc>()
              ..add(UserEvent.profileRequested(actorUserId, userId)),
        child: UserDetailView(actorUserId: actorUserId, userId: userId),
      );

  @override
  Widget build(BuildContext context) => BlocListener<UserBloc, UserState>(
    listenWhen: (previous, current) => previous != current,
    listener: _onStateChanged,
    child: ResponsiveBreakpoints.of(context).largerThan(MOBILE)
        ? UserDetailWeb(actorUserId: actorUserId, userId: userId)
        : UserDetailMobile(actorUserId: actorUserId, userId: userId),
  );

  void _onStateChanged(BuildContext context, UserState state) {
    state.when<void>(
      initial: (_, _) {},
      loading: (_, _) {},
      loaded: (_, _) {},
      created: (_, _) {},
      updated: (_, _) {
        AppNotification.showNotification(
          context,
          title: 'user.notifications.updated'.tr(),
        );
        final navigator = Navigator.of(context, rootNavigator: true);
        if (navigator.canPop()) navigator.pop(true);
      },
      deleted: (_, _, _) {},
      information: (message, _, _) =>
          AppNotification.showNotification(context, title: message.tr()),
      failure: (message, _, _) =>
          AppNotification.showNotificationError(context, title: message),
    );
  }
}
