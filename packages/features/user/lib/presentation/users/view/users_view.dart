import 'package:core/get_it.dart';
import 'package:core/utils/notifications.dart';
import 'package:feature_user/domain/entities/delete_outcome.dart';
import 'package:feature_user/presentation/users/activation_code_issuer.dart';
import 'package:feature_user/presentation/users/bloc/user_bloc.dart';
import 'package:feature_user/presentation/users/bloc/user_event.dart';
import 'package:feature_user/presentation/users/bloc/user_state.dart';
import 'package:feature_user/presentation/users/view/users_mobile.dart';
import 'package:feature_user/presentation/users/view/users_web.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_framework.dart';

class UsersView extends StatelessWidget {
  const UsersView({
    super.key,
    required this.actorUserId,
    required this.isAdmin,
    this.issueActivationCode,
  });

  final int actorUserId;
  final bool isAdmin;
  final ActivationCodeIssuer? issueActivationCode;

  static const String path = '/users';
  static const String name = 'users';

  static Widget create({
    required int actorUserId,
    required bool isAdmin,
    ActivationCodeIssuer? issueActivationCode,
  }) {
    final event = isAdmin
        ? UserEvent.listRequested(actorUserId)
        : UserEvent.profileRequested(actorUserId, actorUserId);
    return BlocProvider(
      create: (_) => getIt<UserBloc>()..add(event),
      child: UsersView(
        actorUserId: actorUserId,
        isAdmin: isAdmin,
        issueActivationCode: issueActivationCode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserBloc, UserState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.message != current.message ||
          previous.deleteOutcome != current.deleteOutcome,
      listener: _onStateChanged,
      child: ResponsiveBreakpoints.of(context).largerThan(MOBILE)
          ? UsersWeb(
              actorUserId: actorUserId,
              isAdmin: isAdmin,
              issueActivationCode: issueActivationCode,
            )
          : UsersMobile(
              actorUserId: actorUserId,
              isAdmin: isAdmin,
              issueActivationCode: issueActivationCode,
            ),
    );
  }

  void _onStateChanged(BuildContext context, UserState state) {
    if (!context.mounted) return;
    if (state.message != null) {
      AppNotification.showNotificationError(context, title: state.message!);
      return;
    }
    final message = switch (state.status) {
      UserStatus.created => 'Usuario creado',
      UserStatus.updated => 'Usuario actualizado',
      UserStatus.deleted => switch (state.deleteOutcome) {
        DeleteOutcome.deleted => 'Usuario eliminado',
        DeleteOutcome.deactivated =>
          'Usuario desactivado para conservar el historial',
        null => null,
      },
      _ => null,
    };
    if (message != null) {
      AppNotification.showNotification(context, title: message);
    }
  }
}
