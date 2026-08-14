import 'package:bloc/bloc.dart';
import 'package:core/errors/result.dart';
import 'package:feature_user/domain/entities/user_address.dart';
import 'package:feature_user/domain/usecases/address_usecases.dart';
import 'package:feature_user/presentation/addresses/bloc/address_event.dart';
import 'package:feature_user/presentation/addresses/bloc/address_state.dart';
import 'package:injectable/injectable.dart';

@injectable
class AddressBloc extends Bloc<AddressEvent, AddressState> {
  AddressBloc(
    this._listAddresses,
    this._createAddress,
    this._updateAddress,
    this._selectPrimaryAddress,
    this._deleteAddress,
  ) : super(const AddressState()) {
    on<AddressListRequested>(_list);
    on<AddressFormRequested>(_openForm);
    on<AddressCreateRequested>(_create);
    on<AddressUpdateRequested>(_update);
    on<AddressPrimaryRequested>(_selectPrimary);
    on<AddressDeleteRequested>(_delete);
  }

  final ListAddresses _listAddresses;
  final CreateAddress _createAddress;
  final UpdateAddress _updateAddress;
  final SelectPrimaryAddress _selectPrimaryAddress;
  final DeleteAddress _deleteAddress;

  AddressState _saving() =>
      state.copyWith(status: AddressStatus.saving, message: null);

  AddressState _actionFailure(String message) =>
      state.copyWith(status: AddressStatus.actionFailure, message: message);

  Future<void> _list(
    AddressListRequested event,
    Emitter<AddressState> emit,
  ) async {
    emit(state.copyWith(status: AddressStatus.loading, message: null));
    final result = await _listAddresses(event.actorUserId, event.userId);
    emit(
      result.fold(
        onSuccess: (addresses) =>
            AddressState(status: AddressStatus.loaded, addresses: addresses),
        onFailure: (_) => const AddressState(
          status: AddressStatus.loadFailure,
          message: 'address.errors.load_list',
        ),
      ),
    );
  }

  Future<void> _openForm(
    AddressFormRequested event,
    Emitter<AddressState> emit,
  ) async {
    emit(const AddressState(status: AddressStatus.loading));
    final addressId = event.addressId;
    if (addressId == null) {
      emit(const AddressState(status: AddressStatus.ready));
      return;
    }
    final result = await _listAddresses(event.actorUserId, event.userId);
    emit(
      result.fold(
        onSuccess: (addresses) {
          final selected = _find(addresses, addressId);
          return selected == null
              ? const AddressState(
                  status: AddressStatus.loadFailure,
                  message: 'address.errors.not_found',
                )
              : AddressState(
                  status: AddressStatus.ready,
                  addresses: addresses,
                  selectedAddress: selected,
                );
        },
        onFailure: (_) => const AddressState(
          status: AddressStatus.loadFailure,
          message: 'address.errors.load',
        ),
      ),
    );
  }

  Future<void> _create(
    AddressCreateRequested event,
    Emitter<AddressState> emit,
  ) async {
    emit(_saving());
    final result = await _createAddress(
      event.actorUserId,
      event.userId,
      event.draft,
    );
    emit(
      result.fold(
        onSuccess: (address) => state.copyWith(
          status: AddressStatus.created,
          addresses: [...state.addresses, address],
          selectedAddress: address,
          message: null,
        ),
        onFailure: (_) => _actionFailure('address.errors.create'),
      ),
    );
  }

  Future<void> _update(
    AddressUpdateRequested event,
    Emitter<AddressState> emit,
  ) async {
    emit(_saving());
    final result = await _updateAddress(
      event.actorUserId,
      event.userId,
      event.addressId,
      event.draft,
    );
    emit(
      result.fold(
        onSuccess: (updated) => state.copyWith(
          status: AddressStatus.updated,
          addresses: state.addresses
              .map((address) => address.id == updated.id ? updated : address)
              .toList(),
          selectedAddress: updated,
          message: null,
        ),
        onFailure: (_) => _actionFailure('address.errors.update'),
      ),
    );
  }

  Future<void> _selectPrimary(
    AddressPrimaryRequested event,
    Emitter<AddressState> emit,
  ) async {
    emit(_saving());
    final result = await _selectPrimaryAddress(
      event.actorUserId,
      event.userId,
      event.addressId,
    );
    emit(
      result.fold(
        onSuccess: (selected) => state.copyWith(
          status: AddressStatus.primaryUpdated,
          addresses: state.addresses
              .map(
                (address) => address.id == selected.id
                    ? selected
                    : address.copyWith(isPrimary: false),
              )
              .toList(),
          message: null,
        ),
        onFailure: (_) => _actionFailure('address.errors.set_primary'),
      ),
    );
  }

  Future<void> _delete(
    AddressDeleteRequested event,
    Emitter<AddressState> emit,
  ) async {
    emit(_saving());
    final deletion = await _deleteAddress(
      event.actorUserId,
      event.userId,
      event.addressId,
    );
    if (deletion case Error()) {
      emit(_actionFailure('address.errors.delete'));
      return;
    }
    final refreshed = await _listAddresses(event.actorUserId, event.userId);
    emit(
      refreshed.fold(
        onSuccess: (addresses) =>
            AddressState(status: AddressStatus.deleted, addresses: addresses),
        onFailure: (_) => _actionFailure('address.errors.reload_after_delete'),
      ),
    );
  }

  UserAddress? _find(List<UserAddress> addresses, int id) {
    for (final address in addresses) {
      if (address.id == id) return address;
    }
    return null;
  }
}
