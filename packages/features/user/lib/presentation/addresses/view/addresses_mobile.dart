import 'package:feature_user/domain/entities/user_address.dart';
import 'package:feature_user/presentation/address_form/view/address_form_view.dart';
import 'package:feature_user/presentation/addresses/bloc/address_bloc.dart';
import 'package:feature_user/presentation/addresses/bloc/address_event.dart';
import 'package:feature_user/presentation/addresses/bloc/address_state.dart';
import 'package:feature_user/presentation/addresses/bloc/address_state_x.dart';
import 'package:feature_user/presentation/addresses/widgets/address_delete_dialog.dart';
import 'package:feature_user/presentation/addresses/widgets/address_list_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class AddressesMobile extends StatelessWidget {
  const AddressesMobile({
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
      appBar: AppBar(title: const Text('Direcciones')),
      body: BlocBuilder<AddressBloc, AddressState>(
        builder: (context, state) => state.resolve(
          loading: () =>
              AddressListContent.loading(onRefresh: () => _refresh(bloc)),
          failure: (_) => AddressListContent.failure(
            onRefresh: () => _refresh(bloc),
            onRetry: () => _reload(bloc),
          ),
          empty: () =>
              AddressListContent.empty(onRefresh: () => _refresh(bloc)),
          data: (resolved) => AddressListContent.data(
            addresses: resolved.addresses,
            onRefresh: () => _refresh(bloc),
            onEdit: (address) => _edit(router, bloc, address),
            onSetPrimary: (address) => _setPrimary(bloc, address),
            onDelete: (address) => _delete(navigatorContext, bloc, address),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('create-address-action'),
        onPressed: () => _create(context),
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Nueva dirección'),
      ),
    );
  }

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
        .skipWhile((state) => state.status != AddressStatus.loading)
        .firstWhere((state) => state.status != AddressStatus.loading);
    _reload(bloc);
    await completed;
  }
}
