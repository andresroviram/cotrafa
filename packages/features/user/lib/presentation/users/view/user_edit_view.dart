import 'package:core/get_it.dart';
import 'package:feature_user/domain/entities/user_profile.dart';
import 'package:feature_user/presentation/users/bloc/user_bloc.dart';
import 'package:feature_user/presentation/users/bloc/user_event.dart';
import 'package:feature_user/presentation/users/bloc/user_state.dart';
import 'package:feature_user/presentation/users/widgets/user_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserEditView extends StatelessWidget {
  const UserEditView({
    required this.actorUserId,
    required this.userId,
    super.key,
  });

  final int actorUserId;
  final int userId;

  static const String path = ':userId/edit';
  static const String name = 'edit-user';

  static Widget create({required int actorUserId, required int userId}) =>
      BlocProvider(
        create: (_) =>
            getIt<UserBloc>()
              ..add(UserEvent.profileRequested(actorUserId, userId)),
        child: UserEditView(actorUserId: actorUserId, userId: userId),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Editar usuario')),
    body: BlocBuilder<UserBloc, UserState>(
      builder: (context, state) {
        final user = _findUser(state.users);
        if (user != null) {
          return UserForm.edit(
            actorUserId: actorUserId,
            user: user,
            showHeading: false,
            topPadding: 24,
          );
        }
        if (state.status == UserStatus.failure) {
          return _LoadFailure(
            onRetry: () => context.read<UserBloc>().add(
              UserEvent.profileRequested(actorUserId, userId),
            ),
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    ),
  );

  UserProfile? _findUser(List<UserProfile> users) {
    for (final user in users) {
      if (user.id == userId) return user;
    }
    return null;
  }
}

class _LoadFailure extends StatelessWidget {
  const _LoadFailure({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('No pudimos cargar el usuario'),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
      ],
    ),
  );
}
