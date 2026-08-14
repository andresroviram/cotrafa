import 'package:bloc_test/bloc_test.dart';
import 'package:core/errors/error.dart';
import 'package:core/errors/result.dart';
import 'package:feature_transfer/domain/entities/transfer_receipt.dart';
import 'package:feature_transfer/domain/repository/i_transfer_repository.dart';
import 'package:feature_transfer/domain/usecases/transfer_usecases.dart';
import 'package:feature_transfer/presentation/transfer/bloc/transfer_history_bloc.dart';
import 'package:feature_transfer/presentation/transfer/bloc/transfer_history_event.dart';
import 'package:feature_transfer/presentation/transfer/bloc/transfer_history_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

final class _MockRepository extends Mock implements ITransferRepository {}

void main() {
  const transfer = TransferReceipt(
    id: 'transfer-1',
    originUserId: 2,
    destinationUserId: 3,
    amountCop: 100,
    status: 'completed',
    description: 'Payment',
    createdAt: 1,
    originSnapshot: 'Origin <origin@test.co>',
    destinationSnapshot: 'Destination <destination@test.co>',
  );

  late _MockRepository repository;

  TransferHistoryBloc buildBloc() =>
      TransferHistoryBloc(ListTransfers(repository));

  setUp(() => repository = _MockRepository());

  test('Freezed event and state use value equality', () {
    expect(
      const TransferHistoryEvent.loadRequested(2),
      const TransferHistoryEvent.loadRequested(2),
    );
    expect(
      const TransferHistoryState(
        status: TransferHistoryStatus.loaded,
        transfers: [transfer],
      ),
      const TransferHistoryState(
        status: TransferHistoryStatus.loaded,
        transfers: [transfer],
      ),
    );
  });

  blocTest<TransferHistoryBloc, TransferHistoryState>(
    'loads the actor transfer history',
    setUp: () {
      when(
        () => repository.listTransfers(2),
      ).thenAnswer((_) async => const Success([transfer]));
    },
    build: buildBloc,
    act: (bloc) => bloc.add(const TransferHistoryEvent.loadRequested(2)),
    expect: () => const [
      TransferHistoryState(status: TransferHistoryStatus.loading),
      TransferHistoryState(
        status: TransferHistoryStatus.loaded,
        transfers: [transfer],
      ),
    ],
  );

  blocTest<TransferHistoryBloc, TransferHistoryState>(
    'exposes typed history failures',
    setUp: () {
      when(
        () => repository.listTransfers(2),
      ).thenAnswer((_) async => const Error(StorageReadFailure()));
    },
    build: buildBloc,
    act: (bloc) => bloc.add(const TransferHistoryEvent.loadRequested(2)),
    expect: () => const [
      TransferHistoryState(status: TransferHistoryStatus.loading),
      TransferHistoryState(
        status: TransferHistoryStatus.failure,
        message: 'Error al leer los datos almacenados.',
      ),
    ],
  );
}
