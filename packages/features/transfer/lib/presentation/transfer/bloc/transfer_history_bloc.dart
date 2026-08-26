import 'package:bloc/bloc.dart';
import 'package:core/errors/result.dart';
import 'package:feature_transfer/domain/usecases/transfer_usecases.dart';
import 'package:feature_transfer/presentation/transfer/bloc/transfer_history_event.dart';
import 'package:feature_transfer/presentation/transfer/bloc/transfer_history_state.dart';
import 'package:injectable/injectable.dart';

@injectable
class TransferHistoryBloc
    extends Bloc<TransferHistoryEvent, TransferHistoryState> {
  TransferHistoryBloc(this._listTransfers)
    : super(const TransferHistoryState.initial()) {
    on<TransferHistoryLoadRequested>(_load);
  }

  final ListTransfers _listTransfers;

  Future<void> _load(
    TransferHistoryLoadRequested event,
    Emitter<TransferHistoryState> emit,
  ) async {
    emit(const TransferHistoryState.loading());
    final result = await _listTransfers(event.actorUserId);
    emit(
      result.fold(
        onSuccess: (transfers) =>
            TransferHistoryState.loaded(transfers: transfers),
        onFailure: (error) =>
            TransferHistoryState.failure(message: error.message),
      ),
    );
  }
}
