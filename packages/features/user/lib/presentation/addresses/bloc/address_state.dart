import 'package:feature_user/domain/entities/user_address.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'address_state.freezed.dart';

enum AddressStatus {
  initial,
  loading,
  loaded,
  ready,
  saving,
  created,
  updated,
  primaryUpdated,
  deleted,
  loadFailure,
  actionFailure,
}

@freezed
abstract class AddressState with _$AddressState {
  const factory AddressState({
    @Default(AddressStatus.initial) AddressStatus status,
    @Default(<UserAddress>[]) List<UserAddress> addresses,
    UserAddress? selectedAddress,
    String? message,
  }) = _AddressState;
}
