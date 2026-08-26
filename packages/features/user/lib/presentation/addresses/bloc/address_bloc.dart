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
  ) : super(const AddressState.initial()) {
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

  AddressState _saving() => AddressState.saving(
    addresses: state.addresses,
    selectedAddress: state.selectedAddress,
  );

  AddressState _actionFailure(String message) => AddressState.actionFailure(
    message: message,
    addresses: state.addresses,
    selectedAddress: state.selectedAddress,
  );

  Future<void> _list(
    AddressListRequested event,
    Emitter<AddressState> emit,
  ) async {
    emit(
      AddressState.loading(
        addresses: state.addresses,
        selectedAddress: state.selectedAddress,
      ),
    );
    final result = await _listAddresses(event.actorUserId, event.userId);
    emit(
      result.fold(
        onSuccess: (addresses) => AddressState.loaded(addresses: addresses),
        onFailure: (error) => AddressState.loadFailure(message: error.message),
      ),
    );
  }

  Future<void> _openForm(
    AddressFormRequested event,
    Emitter<AddressState> emit,
  ) async {
    emit(const AddressState.loading());
    final addressId = event.addressId;
    if (addressId == null) {
      emit(const AddressState.ready());
      return;
    }
    final result = await _listAddresses(event.actorUserId, event.userId);
    emit(
      result.fold(
        onSuccess: (addresses) {
          final selected = _find(addresses, addressId);
          return selected == null
              ? const AddressState.loadFailure(message: 'Address not found.')
              : AddressState.ready(
                  addresses: addresses,
                  selectedAddress: selected,
                );
        },
        onFailure: (error) => AddressState.loadFailure(message: error.message),
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
        onSuccess: (address) => AddressState.created(
          addresses: [...state.addresses, address],
          selectedAddress: address,
        ),
        onFailure: (error) => _actionFailure(error.message),
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
        onSuccess: (updated) => AddressState.updated(
          addresses: state.addresses
              .map((address) => address.id == updated.id ? updated : address)
              .toList(),
          selectedAddress: updated,
        ),
        onFailure: (error) => _actionFailure(error.message),
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
        onSuccess: (selected) => AddressState.primaryUpdated(
          addresses: state.addresses
              .map(
                (address) => address.id == selected.id
                    ? selected
                    : address.copyWith(isPrimary: false),
              )
              .toList(),
          selectedAddress: selected,
        ),
        onFailure: (error) => _actionFailure(error.message),
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
    if (deletion case Error(error: final error)) {
      emit(_actionFailure(error.message));
      return;
    }
    final refreshed = await _listAddresses(event.actorUserId, event.userId);
    emit(
      refreshed.fold(
        onSuccess: (addresses) => AddressState.deleted(addresses: addresses),
        onFailure: (error) => _actionFailure(error.message),
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
