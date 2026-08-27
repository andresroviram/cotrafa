import 'package:core/errors/error.dart';
import 'package:core/errors/result.dart';
import 'package:feature_transfer/data/datasources/transfer_local_datasource.dart';
import 'package:feature_transfer/data/models/transfer_party_model.dart';
import 'package:feature_transfer/data/models/transfer_receipt_model.dart';
import 'package:feature_transfer/data/repository/transfer_repository_impl.dart';
import 'package:feature_transfer/domain/entities/receipt_action.dart';
import 'package:feature_transfer/domain/entities/transfer_command.dart';
import 'package:feature_transfer/domain/entities/transfer_party.dart';
import 'package:feature_transfer/domain/entities/transfer_receipt.dart';
import 'package:feature_transfer/domain/usecases/transfer_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

final class _MockDatasource extends Mock implements ITransferLocalDatasource {}

void main() {
  const command = TransferCommand(
    actorId: 2,
    originId: 2,
    destinationId: 3,
    amountCop: 100,
  );
  const receipt = TransferReceipt(
    id: 'receipt-1',
    originUserId: 2,
    destinationUserId: 3,
    amountCop: 100,
    status: 'completed',
    description: null,
    createdAt: 1,
    originSnapshot: 'Origin <origin@test.co>',
    destinationSnapshot: 'Destination <destination@test.co>',
  );
  const receiptModel = TransferReceiptModel(
    id: 'receipt-1',
    originUserId: 2,
    destinationUserId: 3,
    amountCop: 100,
    status: 'completed',
    description: null,
    createdAt: 1,
    originSnapshot: 'Origin <origin@test.co>',
    destinationSnapshot: 'Destination <destination@test.co>',
  );
  const parties = [
    TransferParty(
      id: 2,
      fullName: 'Origin',
      email: 'origin@test.co',
      balanceCop: 500,
    ),
  ];
  const partyModels = [
    TransferPartyModel(
      id: 2,
      fullName: 'Origin',
      email: 'origin@test.co',
      balanceCop: 500,
    ),
  ];

  late _MockDatasource datasource;
  late TransferRepositoryImpl repository;

  setUpAll(() => registerFallbackValue(command));

  setUp(() {
    datasource = _MockDatasource();
    repository = TransferRepositoryImpl(datasource);
  });

  test(
    'repository and use cases expose transfers through Core Result',
    () async {
      when(
        () => datasource.listParties(2),
      ).thenAnswer((_) async => partyModels);
      when(
        () => datasource.listTransfers(2),
      ).thenAnswer((_) async => [receiptModel]);
      when(
        () => datasource.createTransfer(command),
      ).thenAnswer((_) async => receiptModel);
      when(
        () => datasource.getReceipt('receipt-1'),
      ).thenAnswer((_) async => receiptModel);

      expect((await ListTransferParties(repository)(2)).valueOrNull, parties);
      expect((await ListTransfers(repository)(2)).valueOrNull, [receipt]);
      expect(await CreateTransfer(repository)(command), const Success(receipt));
      expect(
        await GetTransferReceipt(repository)('receipt-1'),
        const Success(receipt),
      );
      expect(receiptModel.toEntity(), receipt);
      expect(partyModels.single.toEntity(), parties.single);
    },
  );

  test('repository maps typed and unknown datasource failures', () async {
    when(
      () => datasource.createTransfer(any()),
    ).thenThrow(const ValidationException(message: 'Insufficient balance.'));
    when(
      () => datasource.getReceipt(any()),
    ).thenThrow(StateError('database failure'));

    expect(
      await repository.createTransfer(command),
      const Error<TransferReceipt>(
        ValidationFailure(message: 'Insufficient balance.'),
      ),
    );
    expect(
      await repository.getReceipt('missing'),
      const Error<TransferReceipt>(StorageReadFailure()),
    );
  });

  test('receipt actions remain denied through the use case', () async {
    expect(
      await const RequestReceiptAction()('receipt-1', ReceiptAction.share),
      const Error<void>(
        ValidationFailure(message: 'Transfer receipts are read-only.'),
      ),
    );
  });

  test('create use case validates and normalizes the command', () async {
    const normalized = TransferCommand(
      actorId: 2,
      originId: 2,
      destinationId: 3,
      amountCop: 100,
      description: 'Rent',
    );
    when(
      () => datasource.createTransfer(normalized),
    ).thenAnswer((_) async => receiptModel);

    expect(
      await CreateTransfer(repository)(
        const TransferCommand(
          actorId: 2,
          originId: 2,
          destinationId: 3,
          amountCop: 100,
          description: ' Rent ',
        ),
      ),
      const Success(receipt),
    );
    expect(
      await CreateTransfer(repository)(
        const TransferCommand(
          actorId: 2,
          originId: 2,
          destinationId: 2,
          amountCop: 100,
        ),
      ),
      const Error<TransferReceipt>(
        ValidationFailure(message: 'Origin and destination must be different.'),
      ),
    );
  });
}
