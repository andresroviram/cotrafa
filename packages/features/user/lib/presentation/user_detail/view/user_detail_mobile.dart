import 'package:feature_user/domain/entities/user_profile.dart';
import 'package:feature_user/presentation/addresses/view/addresses_view.dart';
import 'package:feature_user/presentation/users/bloc/user_bloc.dart';
import 'package:feature_user/presentation/users/bloc/user_event.dart';
import 'package:feature_user/presentation/users/bloc/user_state.dart';
import 'package:feature_user/presentation/user_detail/widgets/user_detail_content.dart';
import 'package:feature_user/presentation/shared/widgets/user_form_modal.dart';
import 'package:feature_user/presentation/shared/widgets/user_load_failure.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class UserDetailMobile extends StatelessWidget {
  const UserDetailMobile({
    required this.actorUserId,
    required this.userId,
    super.key,
  });

  final int actorUserId;
  final int userId;

  @override
  Widget build(BuildContext context) => BlocBuilder<UserBloc, UserState>(
    builder: (context, state) => state.when(
      initial: (_, _) => _loading(),
      loading: (users, _) => users.isEmpty ? _loading() : _data(context, state),
      loaded: (_, _) => _data(context, state),
      created: (_, _) => _data(context, state),
      updated: (_, _) => _data(context, state),
      deleted: (_, _, _) => _data(context, state),
      information: (_, _, _) => _data(context, state),
      failure: (_, users, _) =>
          users.isEmpty ? _failure(context) : _data(context, state),
    ),
  );

  Widget _data(BuildContext context, UserState state) {
    final user = _findUser(state.users);
    return user == null
        ? _failure(context)
        : UserDetailContent(
            user: user,
            onRefresh: () => _reload(context),
            onEdit: () => _edit(context, user),
            onAddresses: () => _openAddresses(context),
          );
  }

  Widget _loading() => Scaffold(
    appBar: AppBar(),
    body: const Center(child: CircularProgressIndicator()),
  );

  Widget _failure(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: UserLoadFailure(onRetry: () => _reload(context)),
  );

  UserProfile? _findUser(List<UserProfile> users) {
    for (final user in users) {
      if (user.id == userId) return user;
    }
    return null;
  }

  void _reload(BuildContext context) => context.read<UserBloc>().add(
    UserEvent.profileRequested(actorUserId, userId),
  );

  Future<void> _edit(BuildContext context, UserProfile user) async {
    final updated = await showUserFormModal(
      context,
      actorUserId: actorUserId,
      user: user,
    );
    if (updated == true && context.mounted) _reload(context);
  }

  Future<void> _openAddresses(BuildContext context) => context.pushNamed<void>(
    AddressesView.name,
    pathParameters: {'userId': '$userId'},
  );
}
