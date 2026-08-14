import 'package:feature_transfer/presentation/transfer/bloc/transfer_state.dart';

extension TransferStateX on TransferState {
  bool get isLoading =>
      (status == TransferStatus.initial || status == TransferStatus.loading) &&
      parties.isEmpty;

  bool get hasFailure =>
      status == TransferStatus.failure && message != null && parties.isEmpty;

  bool get isSubmitting => status == TransferStatus.submitting;

  T resolve<T>({
    required T Function() loading,
    required T Function(String message) failure,
    required T Function(TransferState state) data,
    T Function()? empty,
  }) {
    if (isLoading) return loading();
    if (hasFailure) return failure(message!);
    if (parties.isEmpty) return empty?.call() ?? data(this);
    return data(this);
  }
}
