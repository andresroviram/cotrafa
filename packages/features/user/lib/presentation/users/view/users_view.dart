import 'package:core/get_it.dart';
import 'package:feature_user/domain/entities/user_profile.dart';
import 'package:feature_user/presentation/users/activation_code_issuer.dart';
import 'package:feature_user/presentation/users/bloc/user_bloc.dart';
import 'package:feature_user/presentation/users/bloc/user_event.dart';
import 'package:feature_user/presentation/users/bloc/user_state.dart';
import 'package:feature_user/presentation/users/view/user_detail_view.dart';
import 'package:feature_user/presentation/users/view/user_edit_view.dart';
import 'package:feature_user/presentation/users/view/users_mobile.dart';
import 'package:feature_user/presentation/users/view/users_web.dart';
import 'package:feature_user/presentation/users/widgets/activation_code_dialog.dart';
import 'package:feature_user/presentation/users/widgets/user_card.dart';
import 'package:feature_user/presentation/users/widgets/user_form_modal.dart';
import 'package:feature_user/presentation/users/widgets/user_search_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
    return BlocBuilder<UserBloc, UserState>(
      buildWhen: (previous, current) =>
          previous.status != current.status ||
          previous.users != current.users ||
          previous.message != current.message ||
          previous.searchQuery != current.searchQuery,
      builder: (context, state) {
        final content = _body(context, state, _visibleUsers(state));
        final body = Column(
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
                child: content,
              ),
            ),
          ],
        );
        final onCreate = isAdmin && issueActivationCode != null
            ? () => _openCreate(context)
            : null;
        final page = ResponsiveBreakpoints.of(context).largerThan(MOBILE)
            ? UsersWeb(body: body, onCreate: onCreate)
            : UsersMobile(body: body, onCreate: onCreate);
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: page,
        );
      },
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

  Future<void> _openCreate(BuildContext context) async {
    final issuer = issueActivationCode;
    if (issuer == null) return;
    await showUserFormModal(
      context,
      actorUserId: actorUserId,
      issueActivationCode: issuer,
    );
  }

  Future<void> _generateActivationCode(
    BuildContext context,
    UserProfile user,
  ) async {
    final issuer = issueActivationCode;
    if (issuer == null) return;
    final code = await issuer(actorUserId, user.email);
    if (!context.mounted) return;
    if (code == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos generar el código')),
      );
      return;
    }
    await showActivationCodeDialog(context, code: code);
  }

  Future<void> _openEdit(BuildContext context, UserProfile user) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final updated = await context.pushNamed<bool>(
      UserEditView.name,
      pathParameters: {'userId': '${user.id}'},
    );
    if (updated != true || !context.mounted) return;
    _load(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Usuario actualizado')));
  }

  Future<void> _openDetail(BuildContext context, UserProfile user) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await context.pushNamed<bool>(
      UserDetailView.name,
      pathParameters: {'userId': '${user.id}'},
    );
    if (context.mounted) _load(context);
  }

  List<UserProfile> _visibleUsers(UserState state) {
    if (state.searchQuery.isEmpty) return state.users;
    return state.users.where((user) {
      final query = state.searchQuery;
      return user.displayName.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query);
    }).toList();
  }

  Widget _body(BuildContext context, UserState state, List<UserProfile> users) {
    if (state.status == UserStatus.loading && state.users.isEmpty) {
      return _staticBody(const Center(child: CircularProgressIndicator()));
    }
    if (state.status == UserStatus.failure) {
      return _staticBody(_UsersFailure(onRetry: () => _load(context)));
    }
    if (users.isEmpty) {
      return _staticBody(const _EmptyUsers());
    }
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
        return UserCard(
          user: user,
          onTap: () => _openDetail(context, user),
          onEdit: isAdmin || user.id == actorUserId
              ? () => _openEdit(context, user)
              : null,
          onGenerateActivationCode: canGenerateCode
              ? () => _generateActivationCode(context, user)
              : null,
        );
      },
    );
  }

  Widget _staticBody(Widget child) => CustomScrollView(
    physics: const AlwaysScrollableScrollPhysics(),
    slivers: [SliverFillRemaining(hasScrollBody: false, child: child)],
  );
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
