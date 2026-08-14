import 'package:feature_transfer/domain/entities/transfer_receipt.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'transfer_history_state.freezed.dart';

enum TransferHistoryStatus { initial, loading, loaded, failure }

@freezed
abstract class TransferHistoryState with _$TransferHistoryState {
  const factory TransferHistoryState({
    @Default(TransferHistoryStatus.initial) TransferHistoryStatus status,
    @Default(<TransferReceipt>[]) List<TransferReceipt> transfers,
    String? message,
  }) = _TransferHistoryState;
}
