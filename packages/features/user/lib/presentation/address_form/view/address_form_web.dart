import 'package:feature_user/presentation/address_form/widgets/address_form.dart';
import 'package:feature_user/presentation/addresses/bloc/address_bloc.dart';
import 'package:feature_user/presentation/addresses/bloc/address_event.dart';
import 'package:feature_user/presentation/addresses/bloc/address_state.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feature_user/presentation/shared/widgets/user_load_failure.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddressFormWeb extends StatelessWidget {
  const AddressFormWeb({
    required this.actorUserId,
    required this.userId,
    required this.addressId,
    super.key,
  });

  final int actorUserId;
  final int userId;
  final int? addressId;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text((addressId == null ? 'address.new' : 'address.edit').tr()),
    ),
    body: Center(
      child: SizedBox(
        width: 680,
        child: BlocBuilder<AddressBloc, AddressState>(
          builder: (context, state) => state.when(
            initial: (_, _) => _loading(),
            loading: (_, _) => _loading(),
            loaded: (_, _) => _form(state),
            ready: (_, _) => _form(state),
            saving: (_, _) => _form(state, isSaving: true),
            created: (_, _) => _form(state),
            updated: (_, _) => _form(state),
            primaryUpdated: (_, _) => _form(state),
            deleted: (_, _) => _form(state),
            loadFailure: (_, _, _) => _failure(context),
            actionFailure: (_, _, _) => _form(state),
          ),
        ),
      ),
    ),
  );

  Widget _loading() => const Center(child: CircularProgressIndicator());

  Widget _form(AddressState state, {bool isSaving = false}) => AddressForm(
    actorUserId: actorUserId,
    userId: userId,
    address: state.selectedAddress,
    isSaving: isSaving,
  );

  Widget _failure(BuildContext context) => UserLoadFailure(
    onRetry: () => context.read<AddressBloc>().add(
      AddressEvent.formRequested(actorUserId, userId, addressId: addressId),
    ),
  );
}
