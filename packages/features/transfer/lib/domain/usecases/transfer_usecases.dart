import 'package:core/errors/error.dart';
import 'package:core/errors/result.dart';
import 'package:feature_transfer/domain/entities/receipt_action.dart';
import 'package:feature_transfer/domain/entities/transfer_command.dart';
import 'package:feature_transfer/domain/entities/transfer_party.dart';
import 'package:feature_transfer/domain/entities/transfer_receipt.dart';
import 'package:feature_transfer/domain/repository/i_transfer_repository.dart';
import 'package:injectable/injectable.dart';

abstract class _TransferUseCase {
  const _TransferUseCase(this.repository);

  final ITransferRepository repository;
}

@injectable
final class ListTransferParties extends _TransferUseCase {
  const ListTransferParties(super.repository);

  Future<Result<List<TransferParty>>> call(int actorUserId) =>
      repository.listParties(actorUserId);
}

@injectable
final class ListTransfers extends _TransferUseCase {
  const ListTransfers(super.repository);

  Future<Result<List<TransferReceipt>>> call(int actorUserId) =>
      repository.listTransfers(actorUserId);
}

@injectable
final class CreateTransfer extends _TransferUseCase {
  const CreateTransfer(super.repository);

  Future<Result<TransferReceipt>> call(TransferCommand command) {
    if (command.amountCop <= 0) {
      return Future.value(
        const Error<TransferReceipt>(
          ValidationFailure(
            message: 'Transfer amount must be greater than zero.',
          ),
        ),
      );
    }
    if (command.originId == command.destinationId) {
      return Future.value(
        const Error<TransferReceipt>(
          ValidationFailure(
            message: 'Origin and destination must be different.',
          ),
        ),
      );
    }
    final description = command.description?.trim();
    return repository.createTransfer(
      TransferCommand(
        actorId: command.actorId,
        originId: command.originId,
        destinationId: command.destinationId,
        amountCop: command.amountCop,
        description: description == null || description.isEmpty
            ? null
            : description,
      ),
    );
  }
}

@injectable
final class GetTransferReceipt extends _TransferUseCase {
  const GetTransferReceipt(super.repository);

  Future<Result<TransferReceipt>> call(String id) {
    final normalizedId = id.trim();
    return normalizedId.isEmpty
        ? Future.value(
            const Error<TransferReceipt>(
              ValidationFailure(message: 'Receipt id is required.'),
            ),
          )
        : repository.getReceipt(normalizedId);
  }
}

@injectable
final class RequestReceiptAction {
  const RequestReceiptAction();

  Future<Result<void>> call(String id, ReceiptAction action) => Future.value(
    const Error<void>(
      ValidationFailure(message: 'Transfer receipts are read-only.'),
    ),
  );
}
