import 'package:feature_user/domain/entities/user_profile.dart';
import 'package:feature_user/presentation/users/bloc/user_bloc.dart';
import 'package:feature_user/presentation/users/bloc/user_event.dart';
import 'package:feature_user/presentation/users/bloc/user_state.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feature_user/presentation/shared/widgets/user_form.dart';
import 'package:feature_user/presentation/shared/widgets/user_load_failure.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserEditMobile extends StatelessWidget {
  const UserEditMobile({
    required this.actorUserId,
    required this.userId,
    super.key,
  });

  final int actorUserId;
  final int userId;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('user.form.edit_title'.tr())),
    body: BlocBuilder<UserBloc, UserState>(
      builder: (context, state) => state.when(
        initial: (_, _) => _loading(),
        loading: (users, _) =>
            users.isEmpty ? _loading() : _data(context, state),
        loaded: (_, _) => _data(context, state),
        created: (_, _) => _data(context, state),
        updated: (_, _) => _data(context, state),
        deleted: (_, _, _) => _data(context, state),
        information: (_, _, _) => _data(context, state),
        failure: (_, users, _) =>
            users.isEmpty ? _failure(context) : _data(context, state),
      ),
    ),
  );

  Widget _loading() => const Center(child: CircularProgressIndicator());

  Widget _data(BuildContext context, UserState state) {
    final user = _findUser(state.users);
    return user == null
        ? _failure(context)
        : UserForm.edit(
            actorUserId: actorUserId,
            user: user,
            showHeading: false,
            topPadding: 24,
          );
  }

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
