import 'package:feature_user/domain/entities/user_address.dart';
import 'package:feature_user/presentation/address_form/view/address_form_view.dart';
import 'package:feature_user/presentation/addresses/bloc/address_bloc.dart';
import 'package:feature_user/presentation/addresses/bloc/address_event.dart';
import 'package:feature_user/presentation/addresses/bloc/address_state.dart';
import 'package:feature_user/presentation/addresses/widgets/address_delete_dialog.dart';
import 'package:feature_user/presentation/addresses/widgets/address_list_content.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class AddressesWeb extends StatelessWidget {
  const AddressesWeb({
    required this.actorUserId,
    required this.userId,
    super.key,
  });

  final int actorUserId;
  final int userId;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AddressBloc>();
    final router = GoRouter.maybeOf(context);
    final navigatorContext = Navigator.of(context, rootNavigator: true).context;
    return Scaffold(
      appBar: AppBar(title: Text('address.title'.tr())),
      body: Center(
        child: SizedBox(
          width: 760,
          child: BlocBuilder<AddressBloc, AddressState>(
            builder: (context, state) => state.when(
              initial: (_, _) => _loading(bloc),
              loading: (addresses, _) => addresses.isEmpty
                  ? _loading(bloc)
                  : _data(state, router, bloc, navigatorContext),
              loaded: (addresses, _) => addresses.isEmpty
                  ? _empty(bloc)
                  : _data(state, router, bloc, navigatorContext),
              ready: (addresses, _) => addresses.isEmpty
                  ? _empty(bloc)
                  : _data(state, router, bloc, navigatorContext),
              saving: (addresses, _) => addresses.isEmpty
                  ? _empty(bloc)
                  : _data(state, router, bloc, navigatorContext),
              created: (_, _) => _data(state, router, bloc, navigatorContext),
              updated: (_, _) => _data(state, router, bloc, navigatorContext),
              primaryUpdated: (_, _) =>
                  _data(state, router, bloc, navigatorContext),
              deleted: (addresses, _) => addresses.isEmpty
                  ? _empty(bloc)
                  : _data(state, router, bloc, navigatorContext),
              loadFailure: (_, _, _) => _failure(bloc),
              actionFailure: (_, addresses, _) => addresses.isEmpty
                  ? _empty(bloc)
                  : _data(state, router, bloc, navigatorContext),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('create-address-action'),
        onPressed: () => _create(context),
        icon: const Icon(Icons.add_location_alt_outlined),
        label: Text('address.new'.tr()),
      ),
    );
  }

  AddressListContent _loading(AddressBloc bloc) =>
      AddressListContent.loading(onRefresh: () => _refresh(bloc));

  AddressListContent _failure(AddressBloc bloc) => AddressListContent.failure(
    onRefresh: () => _refresh(bloc),
    onRetry: () => _reload(bloc),
  );

  AddressListContent _empty(AddressBloc bloc) =>
      AddressListContent.empty(onRefresh: () => _refresh(bloc));

  AddressListContent _data(
    AddressState state,
    GoRouter? router,
    AddressBloc bloc,
    BuildContext navigatorContext,
  ) => AddressListContent.data(
    addresses: state.addresses,
    onRefresh: () => _refresh(bloc),
    onEdit: (address) => _edit(router, bloc, address),
    onSetPrimary: (address) => _setPrimary(bloc, address),
    onDelete: (address) => _delete(navigatorContext, bloc, address),
  );

  Future<void> _create(BuildContext context) async {
    final created = await context.pushNamed<bool>(
      AddressFormView.createName,
      pathParameters: {'userId': '$userId'},
    );
    if (created == true && context.mounted) {
      _reload(context.read<AddressBloc>());
    }
  }

  Future<void> _edit(
    GoRouter? router,
    AddressBloc bloc,
    UserAddress address,
  ) async {
    if (router == null) return;
    final updated = await router.pushNamed<bool>(
      AddressFormView.editName,
      pathParameters: {'userId': '$userId', 'addressId': '${address.id}'},
    );
    if (updated == true) _reload(bloc);
  }

  void _setPrimary(AddressBloc bloc, UserAddress address) =>
      bloc.add(AddressEvent.primaryRequested(actorUserId, userId, address.id));

  Future<void> _delete(
    BuildContext context,
    AddressBloc bloc,
    UserAddress address,
  ) async {
    final confirmed = await showAddressDeleteDialog(context, address: address);
    if (!confirmed || !context.mounted) return;
    bloc.add(AddressEvent.deleteRequested(actorUserId, userId, address.id));
  }

  void _reload(AddressBloc bloc) =>
      bloc.add(AddressEvent.listRequested(actorUserId, userId));

  Future<void> _refresh(AddressBloc bloc) async {
    final completed = bloc.stream
        .skipWhile((state) => !_isLoading(state))
        .firstWhere((state) => !_isLoading(state));
    _reload(bloc);
    await completed;
  }
}

bool _isLoading(AddressState state) => state.when(
  initial: (_, _) => false,
  loading: (_, _) => true,
  loaded: (_, _) => false,
  ready: (_, _) => false,
  saving: (_, _) => false,
  created: (_, _) => false,
  updated: (_, _) => false,
  primaryUpdated: (_, _) => false,
  deleted: (_, _) => false,
  loadFailure: (_, _, _) => false,
  actionFailure: (_, _, _) => false,
);
