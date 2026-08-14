import 'package:feature_user/domain/entities/user_profile.dart';
import 'package:feature_user/presentation/users/activation_code_issuer.dart';
import 'package:feature_user/presentation/users/bloc/user_bloc.dart';
import 'package:feature_user/presentation/users/bloc/user_event.dart';
import 'package:feature_user/presentation/users/bloc/user_state.dart';
import 'package:feature_user/presentation/users/bloc/user_state_x.dart';
import 'package:feature_user/presentation/user_detail/view/user_detail_view.dart';
import 'package:feature_user/presentation/user_edit/view/user_edit_view.dart';
import 'package:feature_user/presentation/users/widgets/activation_code_dialog.dart';
import 'package:feature_user/presentation/users/widgets/user_delete_dialog.dart';
import 'package:feature_user/presentation/shared/widgets/user_form_modal.dart';
import 'package:feature_user/presentation/users/widgets/users_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class UsersWeb extends StatelessWidget {
  const UsersWeb({
    super.key,
    required this.actorUserId,
    required this.isAdmin,
    required this.issueActivationCode,
  });

  final int actorUserId;
  final bool isAdmin;
  final ActivationCodeIssuer? issueActivationCode;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<UserBloc>();
    final router = GoRouter.maybeOf(context);
    final navigatorContext = Navigator.of(context, rootNavigator: true).context;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: 960,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 8, 8),
                  child: Row(
                    children: [
                      Text(
                        'Lista de usuarios',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const Spacer(),
                      if (_canCreate) ...[
                        FilledButton.icon(
                          key: const Key('create-user-action'),
                          onPressed: () => _openCreate(context),
                          icon: const Icon(Icons.person_add_outlined),
                          label: const Text('Nuevo usuario'),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: BlocBuilder<UserBloc, UserState>(
                    buildWhen: _buildWhen,
                    builder: (context, state) => state.resolve(
                      loading: () => UsersContent.loading(
                        actorUserId: actorUserId,
                        isAdmin: isAdmin,
                        issueActivationCode: issueActivationCode,
                      ),
                      failure: (_) => UsersContent.failure(
                        actorUserId: actorUserId,
                        isAdmin: isAdmin,
                        issueActivationCode: issueActivationCode,
                      ),
                      empty: () => UsersContent.empty(
                        actorUserId: actorUserId,
                        isAdmin: isAdmin,
                        issueActivationCode: issueActivationCode,
                      ),
                      data: (resolved) => UsersContent.data(
                        state: resolved,
                        actorUserId: actorUserId,
                        isAdmin: isAdmin,
                        issueActivationCode: issueActivationCode,
                        onOpenDetail: (user) => _openDetail(router, bloc, user),
                        onOpenEdit: (user) => _openEdit(router, bloc, user),
                        onGenerateActivationCode: (user) =>
                            _generateActivationCode(
                              navigatorContext,
                              bloc,
                              user,
                            ),
                        onDelete: (user) =>
                            _deleteUser(navigatorContext, bloc, user),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool get _canCreate => isAdmin && issueActivationCode != null;

  Future<void> _openCreate(BuildContext context) async {
    if (issueActivationCode == null) return;
    await showUserFormModal(context, actorUserId: actorUserId);
  }

  void _load(UserBloc bloc) => bloc.add(
    isAdmin
        ? UserEvent.listRequested(actorUserId)
        : UserEvent.profileRequested(actorUserId, actorUserId),
  );

  Future<void> _openDetail(
    GoRouter? router,
    UserBloc bloc,
    UserProfile user,
  ) async {
    if (router == null) return;
    FocusManager.instance.primaryFocus?.unfocus();
    await router.pushNamed<bool>(
      UserDetailView.name,
      pathParameters: {'userId': '${user.id}'},
    );
    _load(bloc);
  }

  Future<void> _openEdit(
    GoRouter? router,
    UserBloc bloc,
    UserProfile user,
  ) async {
    if (router == null) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final updated = await router.pushNamed<bool>(
      UserEditView.name,
      pathParameters: {'userId': '${user.id}'},
    );
    if (updated == true) _load(bloc);
  }

  Future<void> _generateActivationCode(
    BuildContext context,
    UserBloc bloc,
    UserProfile user,
  ) async {
    final issuer = issueActivationCode;
    if (issuer == null) return;
    final code = await issuer(actorUserId, user.email);
    if (!context.mounted) return;
    if (code == null) {
      bloc.add(
        const UserEvent.notificationRequested('No pudimos generar el código'),
      );
      return;
    }
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

  Future<void> _deleteUser(
    BuildContext context,
    UserBloc bloc,
    UserProfile user,
  ) async {
    if (!await showUserDeleteDialog(context, user: user) || !context.mounted) {
      return;
    }
    bloc.add(UserEvent.deleteRequested(actorUserId, user.id));
  }
}

bool _buildWhen(UserState previous, UserState current) =>
    previous.status != current.status ||
    previous.users != current.users ||
    previous.searchQuery != current.searchQuery;
