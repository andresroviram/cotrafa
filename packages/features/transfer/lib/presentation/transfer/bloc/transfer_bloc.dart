import 'package:bloc/bloc.dart';
import 'package:core/errors/result.dart';
import 'package:feature_transfer/domain/entities/transfer_command.dart';
import 'package:feature_transfer/domain/usecases/transfer_usecases.dart';
import 'package:feature_transfer/presentation/transfer/bloc/transfer_event.dart';
import 'package:feature_transfer/presentation/transfer/bloc/transfer_state.dart';
import 'package:injectable/injectable.dart';

@injectable
final class TransferBloc extends Bloc<TransferEvent, TransferState> {
  TransferBloc(this._listParties, this._createTransfer)
    : super(const TransferState()) {
    on<TransferLoadRequested>(_load);
    on<TransferCreateRequested>(_create);
  }

  final ListTransferParties _listParties;
  final CreateTransfer _createTransfer;

  Future<void> _load(
    TransferLoadRequested event,
    Emitter<TransferState> emit,
  ) async {
    emit(const TransferState(status: TransferStatus.loading));
    final result = await _listParties(event.actorUserId);
    emit(
      result.fold(
        onSuccess: (parties) =>
            TransferState(status: TransferStatus.loaded, parties: parties),
        onFailure: (failure) => TransferState(
          status: TransferStatus.failure,
          message: failure.message,
        ),
      ),
    );
  }

  Future<void> _create(
    TransferCreateRequested event,
    Emitter<TransferState> emit,
  ) async {
    emit(
      state.copyWith(
        status: TransferStatus.submitting,
        receipt: null,
        message: null,
      ),
    );
    final description = event.description?.trim();
    final result = await _createTransfer(
      TransferCommand(
        actorId: event.actorUserId,
        originId: event.originUserId,
        destinationId: event.destinationUserId,
        amountCop: event.amountCop,
        description: description == null || description.isEmpty
            ? null
            : description,
      ),
    );
    switch (result) {
      case Error(error: final failure):
        emit(
          state.copyWith(
            status: TransferStatus.failure,
            message: failure.message,
          ),
        );
      case Success(value: final receipt):
        var parties = state.parties;
        final refreshed = await _listParties(event.actorUserId);
        if (refreshed case Success(value: final updated)) parties = updated;
        emit(
          state.copyWith(
            status: TransferStatus.completed,
            parties: parties,
            receipt: receipt,
            message: null,
          ),
        );
    }
  }
}
