import 'package:core/get_it.dart';
import 'package:core/utils/notifications.dart';
import 'package:feature_user/presentation/users/bloc/user_bloc.dart';
import 'package:feature_user/presentation/users/bloc/user_event.dart';
import 'package:feature_user/presentation/users/bloc/user_state.dart';
import 'package:feature_user/presentation/users/view/user_detail_mobile.dart';
import 'package:feature_user/presentation/users/view/user_detail_web.dart';
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
    listenWhen: (previous, current) =>
        previous.status != current.status ||
        previous.message != current.message ||
        previous.notificationType != current.notificationType,
    listener: _onStateChanged,
    child: ResponsiveBreakpoints.of(context).largerThan(MOBILE)
        ? UserDetailWeb(actorUserId: actorUserId, userId: userId)
        : UserDetailMobile(actorUserId: actorUserId, userId: userId),
  );

  void _onStateChanged(BuildContext context, UserState state) {
    final message = state.message;
    if (message != null) {
      if (state.notificationType == UserNotificationType.info) {
        AppNotification.showNotification(context, title: message);
      } else {
        AppNotification.showNotificationError(context, title: message);
      }
      return;
    }
    if (state.status == UserStatus.updated) {
      AppNotification.showNotification(context, title: 'Usuario actualizado');
    }
  }
}
