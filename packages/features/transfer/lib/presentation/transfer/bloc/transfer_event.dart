import 'package:freezed_annotation/freezed_annotation.dart';

part 'transfer_event.freezed.dart';

@freezed
sealed class TransferEvent with _$TransferEvent {
  const factory TransferEvent.loadRequested(int actorUserId) =
      TransferLoadRequested;

  const factory TransferEvent.createRequested({
    required int actorUserId,
    required int originUserId,
    required int destinationUserId,
    required int amountCop,
    String? description,
  }) = TransferCreateRequested;
}
