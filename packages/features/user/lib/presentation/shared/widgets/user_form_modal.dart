import 'package:feature_user/domain/entities/user_profile.dart';
import 'package:feature_user/presentation/users/bloc/user_bloc.dart';
import 'package:feature_user/presentation/shared/widgets/user_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<bool?> showUserFormModal(
  BuildContext context, {
  required int actorUserId,
  UserProfile? user,
}) {
  final bloc = context.read<UserBloc>();
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => BlocProvider.value(
      value: bloc,
      child: user == null
          ? UserForm.create(actorUserId: actorUserId)
          : UserForm.edit(actorUserId: actorUserId, user: user),
    ),
  );
}
