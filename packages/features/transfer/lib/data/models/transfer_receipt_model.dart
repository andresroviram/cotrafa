import 'package:equatable/equatable.dart';
import 'package:feature_transfer/domain/entities/transfer_receipt.dart';

final class TransferReceiptModel extends Equatable {
  const TransferReceiptModel({
    required this.id,
    required this.originUserId,
    required this.destinationUserId,
    required this.amountCop,
    required this.status,
    required this.description,
    required this.createdAt,
    required this.originSnapshot,
    required this.destinationSnapshot,
  });

  final String id;
  final int originUserId;
  final int destinationUserId;
  final int amountCop;
  final String status;
  final String? description;
  final int createdAt;
  final String originSnapshot;
  final String destinationSnapshot;

  @override
  List<Object?> get props => <Object?>[
    id,
    originUserId,
    destinationUserId,
    amountCop,
    status,
    description,
    createdAt,
    originSnapshot,
    destinationSnapshot,
  ];
}

extension TransferReceiptModelMapper on TransferReceiptModel {
  TransferReceipt toEntity() => TransferReceipt(
    id: id,
    originUserId: originUserId,
    destinationUserId: destinationUserId,
    amountCop: amountCop,
    status: status,
    description: description,
    createdAt: createdAt,
    originSnapshot: originSnapshot,
    destinationSnapshot: destinationSnapshot,
  );
}
