import 'package:core/get_it.dart';
import 'package:feature_user/presentation/users/bloc/user_bloc.dart';
import 'package:feature_user/presentation/users/bloc/user_event.dart';
import 'package:feature_user/presentation/users/bloc/user_state.dart';
import 'package:feature_user/presentation/users/view/users_mobile.dart';
import 'package:feature_user/presentation/users/view/users_web.dart';
import 'package:feature_user/presentation/users/widgets/user_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_framework.dart';

class UsersView extends StatelessWidget {
  const UsersView({
    super.key,
    required this.actorUserId,
    required this.isAdmin,
  });

  final int actorUserId;
  final bool isAdmin;

  static const String path = '/users';
  static const String name = 'users';

  static Widget create({required int actorUserId, required bool isAdmin}) {
    final event = isAdmin
        ? UserEvent.listRequested(actorUserId)
        : UserEvent.profileRequested(actorUserId, actorUserId);
    return BlocProvider(
      create: (_) => getIt<UserBloc>()..add(event),
      child: UsersView(actorUserId: actorUserId, isAdmin: isAdmin),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      buildWhen: (previous, current) =>
          previous.status != current.status ||
          previous.users != current.users ||
          previous.message != current.message,
      builder: (context, state) {
        final body = _body(context, state);
        void refresh() => _load(context);
        return ResponsiveBreakpoints.of(context).largerThan(MOBILE)
            ? UsersWeb(body: body, onRefresh: refresh)
            : UsersMobile(body: body, onRefresh: refresh);
      },
    );
  }

  void _load(BuildContext context) => context.read<UserBloc>().add(
    isAdmin
        ? UserEvent.listRequested(actorUserId)
        : UserEvent.profileRequested(actorUserId, actorUserId),
  );

  Widget _body(BuildContext context, UserState state) {
    if (state.status == UserStatus.loading && state.users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == UserStatus.failure) {
      return _UsersFailure(onRetry: () => _load(context));
    }
    if (state.users.isEmpty) {
      return const _EmptyUsers();
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      itemCount: state.users.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, index) => UserCard(user: state.users[index]),
    );
  }
}

class _EmptyUsers extends StatelessWidget {
  const _EmptyUsers();

  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.group_outlined, size: 52),
        SizedBox(height: 12),
        Text('Aún no hay usuarios'),
      ],
    ),
  );
}

class _UsersFailure extends StatelessWidget {
  const _UsersFailure({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, size: 52),
        const SizedBox(height: 12),
        const Text('No pudimos cargar los usuarios'),
        const SizedBox(height: 16),
        FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
      ],
    ),
  );
}
