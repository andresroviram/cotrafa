import 'package:feature_user/domain/entities/user_profile.dart';
import 'package:feature_user/presentation/users/bloc/user_bloc.dart';
import 'package:feature_user/presentation/users/bloc/user_event.dart';
import 'package:feature_user/presentation/users/bloc/user_state.dart';
import 'package:feature_user/presentation/users/bloc/user_state_x.dart';
import 'package:feature_user/presentation/users/widgets/user_detail_content.dart';
import 'package:feature_user/presentation/users/widgets/user_form_modal.dart';
import 'package:feature_user/presentation/users/widgets/user_load_failure.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    builder: (context, state) => state.resolve(
      loading: _loading,
      failure: (_) => _failure(context),
      empty: () => _failure(context),
      data: (resolved) {
        final user = _findUser(resolved.users);
        return user == null
            ? _failure(context)
            : UserDetailContent(
                user: user,
                onRefresh: () => _reload(context),
                onEdit: () => _edit(context, user),
                onAddresses: () => _addressesComingSoon(context),
              );
      },
    ),
  );

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

  void _addressesComingSoon(BuildContext context) =>
      context.read<UserBloc>().add(
        const UserEvent.notificationRequested(
          'La gestión de direcciones estará disponible próximamente',
          type: UserNotificationType.info,
        ),
      );
}
