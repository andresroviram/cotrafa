import 'package:core/get_it.dart';
import 'package:core/utils/notifications.dart';
import 'package:feature_user/domain/entities/delete_outcome.dart';
import 'package:feature_user/presentation/users/activation_code_issuer.dart';
import 'package:feature_user/presentation/users/bloc/user_bloc.dart';
import 'package:feature_user/presentation/users/bloc/user_event.dart';
import 'package:feature_user/presentation/users/bloc/user_state.dart';
import 'package:feature_user/presentation/users/view/users_mobile.dart';
import 'package:feature_user/presentation/users/view/users_web.dart';
import 'package:feature_user/presentation/users/widgets/activation_code_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';

class UsersView extends StatefulWidget {
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
  State<UsersView> createState() => _UsersViewState();
}

class _UsersViewState extends State<UsersView> {
  GoRouter? _router;
  String? _previousRoutePath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final router = GoRouter.maybeOf(context);
      if (router == null) return;
      _router = router;
      _previousRoutePath = router.routerDelegate.currentConfiguration.uri.path;
      router.routerDelegate.addListener(_onRouteChanged);
    });
  }

  @override
  void dispose() {
    _router?.routerDelegate.removeListener(_onRouteChanged);
    super.dispose();
  }

  void _onRouteChanged() {
    if (!mounted) return;
    final currentPath = _router!.routerDelegate.currentConfiguration.uri.path;
    final previousPath = _previousRoutePath;
    if (previousPath != null &&
        !_isUsersRoute(previousPath) &&
        currentPath == UsersView.path) {
      _loadScope();
    }
    _previousRoutePath = currentPath;
  }

  bool _isUsersRoute(String path) =>
      path == UsersView.path || path.startsWith('${UsersView.path}/');

  void _loadScope() => context.read<UserBloc>().add(
    widget.isAdmin
        ? UserEvent.listRequested(widget.actorUserId)
        : UserEvent.profileRequested(widget.actorUserId, widget.actorUserId),
  );

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
              actorUserId: widget.actorUserId,
              isAdmin: widget.isAdmin,
              issueActivationCode: widget.issueActivationCode,
            )
          : UsersMobile(
              actorUserId: widget.actorUserId,
              isAdmin: widget.isAdmin,
              issueActivationCode: widget.issueActivationCode,
            ),
    );
  }

  Future<void> _onStateChanged(BuildContext context, UserState state) async {
    if (!context.mounted) return;
    if (state.message != null) {
      if (state.notificationType == UserNotificationType.info) {
        AppNotification.showNotification(context, title: state.message!);
      } else {
        AppNotification.showNotificationError(context, title: state.message!);
      }
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
    if (state.status == UserStatus.created) {
      await _completeCreation(context, state);
    } else if (state.status == UserStatus.updated) {
      _closeRootModal(context);
    }
  }

  Future<void> _completeCreation(BuildContext context, UserState state) async {
    final issuer = widget.issueActivationCode;
    if (issuer == null || state.users.isEmpty) return;
    final bloc = context.read<UserBloc>();
    final code = await issuer(widget.actorUserId, state.users.last.email);
    if (!context.mounted) return;
    if (code == null) {
      bloc.add(
        const UserEvent.notificationRequested(
          'Usuario creado. Genera su código desde la lista de usuarios.',
          type: UserNotificationType.info,
        ),
      );
    } else {
      await showActivationCodeDialog(
        context,
        code: code,
        onCopied: () => bloc.add(
          const UserEvent.notificationRequested(
            'Código copiado',
            type: UserNotificationType.info,
          ),
        ),
      );
    }
    if (context.mounted) _closeRootModal(context);
  }

  void _closeRootModal(BuildContext context) {
    final navigator = Navigator.of(context, rootNavigator: true);
    if (navigator.canPop()) navigator.pop(true);
  }
}
