import 'package:feature_transfer/domain/entities/transfer_receipt.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'transfer_history_state.freezed.dart';

@freezed
sealed class TransferHistoryState with _$TransferHistoryState {
  const factory TransferHistoryState.initial() = TransferHistoryInitial;

  const factory TransferHistoryState.loading() = TransferHistoryLoading;

  const factory TransferHistoryState.loaded({
    required List<TransferReceipt> transfers,
  }) = TransferHistoryLoaded;

  const factory TransferHistoryState.failure({required String message}) =
      TransferHistoryFailure;
}
