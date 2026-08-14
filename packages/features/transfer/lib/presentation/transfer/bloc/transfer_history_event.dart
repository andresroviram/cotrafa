import 'package:freezed_annotation/freezed_annotation.dart';

part 'transfer_history_event.freezed.dart';

@freezed
sealed class TransferHistoryEvent with _$TransferHistoryEvent {
  const factory TransferHistoryEvent.loadRequested(int actorUserId) =
      TransferHistoryLoadRequested;
}
