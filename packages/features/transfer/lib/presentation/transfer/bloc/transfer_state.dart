import 'package:feature_transfer/domain/entities/transfer_party.dart';
import 'package:feature_transfer/domain/entities/transfer_receipt.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'transfer_state.freezed.dart';

@freezed
sealed class TransferState with _$TransferState {
  const factory TransferState.initial({
    @Default(<TransferParty>[]) List<TransferParty> parties,
  }) = TransferInitial;

  const factory TransferState.loading({
    @Default(<TransferParty>[]) List<TransferParty> parties,
  }) = TransferLoading;

  const factory TransferState.loaded({required List<TransferParty> parties}) =
      TransferLoaded;

  const factory TransferState.submitting({
    required List<TransferParty> parties,
  }) = TransferSubmitting;

  const factory TransferState.completed({
    required List<TransferParty> parties,
    required TransferReceipt receipt,
  }) = TransferCompleted;

  const factory TransferState.failure({
    required String message,
    @Default(<TransferParty>[]) List<TransferParty> parties,
  }) = TransferFailure;
}
