import 'package:equatable/equatable.dart';

final class TransferReceipt extends Equatable {
  const TransferReceipt({
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
  List<Object?> get props => [
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
