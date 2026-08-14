import 'package:feature_transfer/domain/entities/transfer_party.dart';
import 'package:feature_transfer/domain/entities/transfer_receipt.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'transfer_state.freezed.dart';

enum TransferStatus { initial, loading, loaded, submitting, completed, failure }

@freezed
abstract class TransferState with _$TransferState {
  const factory TransferState({
    @Default(TransferStatus.initial) TransferStatus status,
    @Default(<TransferParty>[]) List<TransferParty> parties,
    TransferReceipt? receipt,
    String? message,
  }) = _TransferState;
}
