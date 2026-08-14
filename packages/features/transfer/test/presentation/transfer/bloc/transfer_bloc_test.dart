import 'package:bloc_test/bloc_test.dart';
import 'package:core/errors/error.dart';
import 'package:core/errors/result.dart';
import 'package:feature_transfer/domain/entities/transfer_command.dart';
import 'package:feature_transfer/domain/entities/transfer_party.dart';
import 'package:feature_transfer/domain/entities/transfer_receipt.dart';
import 'package:feature_transfer/domain/repository/i_transfer_repository.dart';
import 'package:feature_transfer/domain/usecases/transfer_usecases.dart';
import 'package:feature_transfer/presentation/transfer/bloc/transfer_bloc.dart';
import 'package:feature_transfer/presentation/transfer/bloc/transfer_event.dart';
import 'package:feature_transfer/presentation/transfer/bloc/transfer_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

final class _MockRepository extends Mock implements ITransferRepository {}

void main() {
  const origin = TransferParty(
    id: 2,
    fullName: 'Origin',
    email: 'origin@test.co',
    balanceCop: 500,
  );
  const destination = TransferParty(
    id: 3,
    fullName: 'Destination',
    email: 'destination@test.co',
    balanceCop: 100,
  );
  const updatedOrigin = TransferParty(
    id: 2,
    fullName: 'Origin',
    email: 'origin@test.co',
    balanceCop: 400,
  );
  const updatedDestination = TransferParty(
    id: 3,
    fullName: 'Destination',
    email: 'destination@test.co',
    balanceCop: 200,
  );
  const receipt = TransferReceipt(
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
  const command = TransferCommand(
    actorId: 2,
    originId: 2,
    destinationId: 3,
    amountCop: 100,
    description: 'Payment',
  );

  late _MockRepository repository;

  TransferBloc buildBloc() =>
      TransferBloc(ListTransferParties(repository), CreateTransfer(repository));

  setUpAll(() => registerFallbackValue(command));

  setUp(() => repository = _MockRepository());

  test('Freezed events and state have value equality', () {
    expect(
      const TransferEvent.loadRequested(2),
      const TransferEvent.loadRequested(2),
    );
    expect(
      const TransferState(
        status: TransferStatus.loaded,
        parties: [origin, destination],
      ),
      const TransferState(
        status: TransferStatus.loaded,
        parties: [origin, destination],
      ),
    );
  });

  blocTest<TransferBloc, TransferState>(
    'loads active transfer parties',
    setUp: () {
      when(
        () => repository.listParties(2),
      ).thenAnswer((_) async => const Success([origin, destination]));
    },
    build: buildBloc,
    act: (bloc) => bloc.add(const TransferEvent.loadRequested(2)),
    expect: () => const [
      TransferState(status: TransferStatus.loading),
      TransferState(
        status: TransferStatus.loaded,
        parties: [origin, destination],
      ),
    ],
  );

  blocTest<TransferBloc, TransferState>(
    'creates a transfer and refreshes balances',
    seed: () => const TransferState(
      status: TransferStatus.loaded,
      parties: [origin, destination],
    ),
    setUp: () {
      when(
        () => repository.createTransfer(command),
      ).thenAnswer((_) async => const Success(receipt));
      when(() => repository.listParties(2)).thenAnswer(
        (_) async => const Success([updatedDestination, updatedOrigin]),
      );
    },
    build: buildBloc,
    act: (bloc) => bloc.add(
      const TransferEvent.createRequested(
        actorUserId: 2,
        originUserId: 2,
        destinationUserId: 3,
        amountCop: 100,
        description: 'Payment',
      ),
    ),
    expect: () => const [
      TransferState(
        status: TransferStatus.submitting,
        parties: [origin, destination],
      ),
      TransferState(
        status: TransferStatus.completed,
        parties: [updatedDestination, updatedOrigin],
        receipt: receipt,
      ),
    ],
  );

  blocTest<TransferBloc, TransferState>(
    'keeps the form data available when creation fails',
    seed: () => const TransferState(
      status: TransferStatus.loaded,
      parties: [origin, destination],
    ),
    setUp: () {
      when(() => repository.createTransfer(command)).thenAnswer(
        (_) async =>
            const Error(ValidationFailure(message: 'Insufficient balance.')),
      );
    },
    build: buildBloc,
    act: (bloc) => bloc.add(
      const TransferEvent.createRequested(
        actorUserId: 2,
        originUserId: 2,
        destinationUserId: 3,
        amountCop: 100,
        description: 'Payment',
      ),
    ),
    expect: () => const [
      TransferState(
        status: TransferStatus.submitting,
        parties: [origin, destination],
      ),
      TransferState(
        status: TransferStatus.failure,
        parties: [origin, destination],
        message: 'Insufficient balance.',
      ),
    ],
  );
}
