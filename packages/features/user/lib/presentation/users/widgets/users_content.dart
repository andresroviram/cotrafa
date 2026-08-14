import 'package:feature_user/domain/entities/user_profile.dart';
import 'package:feature_user/presentation/users/activation_code_issuer.dart';
import 'package:feature_user/presentation/users/bloc/user_bloc.dart';
import 'package:feature_user/presentation/users/bloc/user_event.dart';
import 'package:feature_user/presentation/users/bloc/user_state.dart';
import 'package:feature_user/presentation/users/widgets/user_card.dart';
import 'package:feature_user/presentation/users/widgets/user_search_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UsersContent extends StatelessWidget {
  const UsersContent.loading({
    required this.actorUserId,
    required this.isAdmin,
    required this.issueActivationCode,
    super.key,
  }) : state = null,
       onOpenDetail = null,
       onOpenEdit = null,
       onGenerateActivationCode = null,
       onDelete = null,
       _mode = _UsersContentMode.loading;

  const UsersContent.failure({
    required this.actorUserId,
    required this.isAdmin,
    required this.issueActivationCode,
    super.key,
  }) : state = null,
       onOpenDetail = null,
       onOpenEdit = null,
       onGenerateActivationCode = null,
       onDelete = null,
       _mode = _UsersContentMode.failure;

  const UsersContent.empty({
    required this.actorUserId,
    required this.isAdmin,
    required this.issueActivationCode,
    super.key,
  }) : state = null,
       onOpenDetail = null,
       onOpenEdit = null,
       onGenerateActivationCode = null,
       onDelete = null,
       _mode = _UsersContentMode.empty;

  const UsersContent.data({
    required UserState this.state,
    required this.actorUserId,
    required this.isAdmin,
    required this.issueActivationCode,
    required ValueChanged<UserProfile> this.onOpenDetail,
    required ValueChanged<UserProfile> this.onOpenEdit,
    required ValueChanged<UserProfile> this.onGenerateActivationCode,
    required ValueChanged<UserProfile> this.onDelete,
    super.key,
  }) : _mode = _UsersContentMode.data;

  final UserState? state;
  final int actorUserId;
  final bool isAdmin;
  final ActivationCodeIssuer? issueActivationCode;
  final ValueChanged<UserProfile>? onOpenDetail;
  final ValueChanged<UserProfile>? onOpenEdit;
  final ValueChanged<UserProfile>? onGenerateActivationCode;
  final ValueChanged<UserProfile>? onDelete;
  final _UsersContentMode _mode;

  @override
  Widget build(BuildContext context) {
    final body = switch (_mode) {
      _UsersContentMode.loading => _staticBody(
        const Center(child: CircularProgressIndicator()),
      ),
      _UsersContentMode.failure => _staticBody(
        _UsersFailure(onRetry: () => _load(context)),
      ),
      _UsersContentMode.empty => _staticBody(const _EmptyUsers()),
      _UsersContentMode.data => _usersList(context, state!),
    };

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Column(
        children: [
          if (isAdmin)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: UserSearchField(
                onChanged: (query) => context.read<UserBloc>().add(
                  UserEvent.searchChanged(query),
                ),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              key: const Key('user-refresh-indicator'),
              onRefresh: () => _refresh(context),
              child: body,
            ),
          ),
        ],
      ),
    );
  }

  void _load(BuildContext context) => context.read<UserBloc>().add(
    isAdmin
        ? UserEvent.listRequested(actorUserId)
        : UserEvent.profileRequested(actorUserId, actorUserId),
  );

  Future<void> _refresh(BuildContext context) async {
    final bloc = context.read<UserBloc>();
    final completed = bloc.stream
        .skipWhile((state) => state.status != UserStatus.loading)
        .firstWhere((state) => state.status != UserStatus.loading);
    _load(context);
    await completed;
  }

  Widget _usersList(BuildContext context, UserState state) {
    final users = _visibleUsers(state);
    if (users.isEmpty) return _staticBody(const _EmptyUsers());
    return ListView.separated(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      itemCount: users.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, index) {
        final user = users[index];
        final canGenerateCode =
            isAdmin &&
            user.role == 'client' &&
            user.status == 'pendingActivation' &&
            issueActivationCode != null;
        final canDelete =
            isAdmin && user.role == 'client' && user.status != 'inactive';
        return UserCard(
          user: user,
          onTap: () => onOpenDetail!(user),
          onEdit: isAdmin || user.id == actorUserId
              ? () => onOpenEdit!(user)
              : null,
          onGenerateActivationCode: canGenerateCode
              ? () => onGenerateActivationCode!(user)
              : null,
          onDelete: canDelete ? () => onDelete!(user) : null,
        );
      },
    );
  }

  List<UserProfile> _visibleUsers(UserState state) {
    if (state.searchQuery.isEmpty) return state.users;
    return state.users.where((user) {
      final query = state.searchQuery;
      return user.displayName.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query);
    }).toList();
  }

  Widget _staticBody(Widget child) => CustomScrollView(
    physics: const AlwaysScrollableScrollPhysics(),
    slivers: [SliverFillRemaining(hasScrollBody: false, child: child)],
  );
}

enum _UsersContentMode { loading, failure, empty, data }

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
