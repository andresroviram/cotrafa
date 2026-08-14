import 'package:feature_user/domain/entities/user_profile.dart';
import 'package:feature_user/presentation/users/bloc/user_bloc.dart';
import 'package:feature_user/presentation/users/bloc/user_event.dart';
import 'package:feature_user/presentation/users/bloc/user_state.dart';
import 'package:feature_user/presentation/users/bloc/user_state_x.dart';
import 'package:feature_user/presentation/shared/widgets/user_form.dart';
import 'package:feature_user/presentation/shared/widgets/user_load_failure.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserEditWeb extends StatelessWidget {
  const UserEditWeb({
    required this.actorUserId,
    required this.userId,
    super.key,
  });

  final int actorUserId;
  final int userId;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Editar usuario')),
    body: BlocBuilder<UserBloc, UserState>(
      builder: (context, state) => state.resolve(
        loading: () => const Center(child: CircularProgressIndicator()),
        failure: (_) => _failure(context),
        empty: () => _failure(context),
        data: (resolved) {
          final user = _findUser(resolved.users);
          return user == null
              ? _failure(context)
              : UserForm.edit(
                  actorUserId: actorUserId,
                  user: user,
                  showHeading: false,
                  topPadding: 24,
                );
        },
      ),
    ),
  );

  Widget _failure(BuildContext context) => UserLoadFailure(
    onRetry: () => context.read<UserBloc>().add(
      UserEvent.profileRequested(actorUserId, userId),
    ),
  );

  UserProfile? _findUser(List<UserProfile> users) {
    for (final user in users) {
      if (user.id == userId) return user;
    }
    return null;
  }
}
