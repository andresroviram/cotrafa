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
final class CreateTransfer extends _TransferUseCase {
  const CreateTransfer(super.repository);

  Future<Result<TransferReceipt>> call(TransferCommand command) =>
      repository.createTransfer(command);
}

@injectable
final class GetTransferReceipt extends _TransferUseCase {
  const GetTransferReceipt(super.repository);

  Future<Result<TransferReceipt>> call(String id) => repository.getReceipt(id);
}

@injectable
final class RequestReceiptAction extends _TransferUseCase {
  const RequestReceiptAction(super.repository);

  Future<Result<void>> call(String id, ReceiptAction action) =>
      repository.requestReceiptAction(id, action);
}
