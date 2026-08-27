import 'package:bloc/bloc.dart';
import 'package:core/errors/result.dart';
import 'package:feature_transfer/domain/entities/transfer_command.dart';
import 'package:feature_transfer/domain/usecases/transfer_usecases.dart';
import 'package:feature_transfer/presentation/transfer/bloc/transfer_event.dart';
import 'package:feature_transfer/presentation/transfer/bloc/transfer_state.dart';
import 'package:injectable/injectable.dart';

@injectable
class TransferBloc extends Bloc<TransferEvent, TransferState> {
  TransferBloc(this._listParties, this._createTransfer)
    : super(const TransferState.initial()) {
    on<TransferLoadRequested>(_load);
    on<TransferCreateRequested>(_create);
  }

  final ListTransferParties _listParties;
  final CreateTransfer _createTransfer;

  Future<void> _load(
    TransferLoadRequested event,
    Emitter<TransferState> emit,
  ) async {
    emit(TransferState.loading(parties: state.parties));
    final result = await _listParties(event.actorUserId);
    emit(
      result.fold(
        onSuccess: (parties) => TransferState.loaded(parties: parties),
        onFailure: (error) => TransferState.failure(
          message: error.message,
          parties: state.parties,
        ),
      ),
    );
  }

  Future<void> _create(
    TransferCreateRequested event,
    Emitter<TransferState> emit,
  ) async {
    emit(TransferState.submitting(parties: state.parties));
    final result = await _createTransfer(
      TransferCommand(
        actorId: event.actorUserId,
        originId: event.originUserId,
        destinationId: event.destinationUserId,
        amountCop: event.amountCop,
        description: event.description,
      ),
    );
    switch (result) {
      case Error(error: final error):
        emit(
          TransferState.failure(message: error.message, parties: state.parties),
        );
      case Success(value: final receipt):
        var parties = state.parties;
        final refreshed = await _listParties(event.actorUserId);
        if (refreshed case Success(value: final updated)) parties = updated;
        emit(TransferState.completed(parties: parties, receipt: receipt));
    }
  }
}
