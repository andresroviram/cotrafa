import 'package:feature_user/domain/entities/user_address.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'address_state.freezed.dart';

@freezed
sealed class AddressState with _$AddressState {
  const factory AddressState.initial({
    @Default(<UserAddress>[]) List<UserAddress> addresses,
    UserAddress? selectedAddress,
  }) = AddressInitial;

  const factory AddressState.loading({
    @Default(<UserAddress>[]) List<UserAddress> addresses,
    UserAddress? selectedAddress,
  }) = AddressLoading;

  const factory AddressState.loaded({
    required List<UserAddress> addresses,
    UserAddress? selectedAddress,
  }) = AddressLoaded;

  const factory AddressState.ready({
    @Default(<UserAddress>[]) List<UserAddress> addresses,
    UserAddress? selectedAddress,
  }) = AddressReady;

  const factory AddressState.saving({
    @Default(<UserAddress>[]) List<UserAddress> addresses,
    UserAddress? selectedAddress,
  }) = AddressSaving;

  const factory AddressState.created({
    required List<UserAddress> addresses,
    UserAddress? selectedAddress,
  }) = AddressCreated;

  const factory AddressState.updated({
    required List<UserAddress> addresses,
    UserAddress? selectedAddress,
  }) = AddressUpdated;

  const factory AddressState.primaryUpdated({
    required List<UserAddress> addresses,
    UserAddress? selectedAddress,
  }) = AddressPrimaryUpdated;

  const factory AddressState.deleted({
    required List<UserAddress> addresses,
    UserAddress? selectedAddress,
  }) = AddressDeleted;

  const factory AddressState.loadFailure({
    required String message,
    @Default(<UserAddress>[]) List<UserAddress> addresses,
    UserAddress? selectedAddress,
  }) = AddressLoadFailure;

  const factory AddressState.actionFailure({
    required String message,
    @Default(<UserAddress>[]) List<UserAddress> addresses,
    UserAddress? selectedAddress,
  }) = AddressActionFailure;
}
