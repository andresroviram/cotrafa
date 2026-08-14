import 'package:feature_transfer/presentation/transfer/bloc/transfer_history_state.dart';

extension TransferHistoryStateX on TransferHistoryState {
  T resolve<T>({
    required T Function() loading,
    required T Function(String message) failure,
    required T Function() empty,
    required T Function(TransferHistoryState state) data,
  }) => switch (status) {
    TransferHistoryStatus.initial || TransferHistoryStatus.loading => loading(),
    TransferHistoryStatus.failure => failure(message ?? ''),
    TransferHistoryStatus.loaded when transfers.isEmpty => empty(),
    TransferHistoryStatus.loaded => data(this),
  };
}
