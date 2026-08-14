import 'package:core/get_it.dart';
import 'package:feature_user/presentation/users/bloc/user_bloc.dart';
import 'package:feature_user/presentation/users/bloc/user_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    context.watch<UserBloc>();
    return const Center(child: Text('Usuarios'));
  }
}
