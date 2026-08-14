import 'package:feature_user/presentation/addresses/bloc/address_state.dart';

extension AddressStateX on AddressState {
  bool get isBusy =>
      status == AddressStatus.initial ||
      status == AddressStatus.loading ||
      status == AddressStatus.saving;

  T resolve<T>({
    required T Function() loading,
    required T Function(String message) failure,
    required T Function() empty,
    required T Function(AddressState state) data,
  }) => switch (status) {
    AddressStatus.initial || AddressStatus.loading => loading(),
    AddressStatus.loadFailure => failure(message ?? ''),
    _ when addresses.isEmpty && selectedAddress == null => empty(),
    _ => data(this),
  };
}
