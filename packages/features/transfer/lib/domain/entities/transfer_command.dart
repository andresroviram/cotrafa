import 'package:equatable/equatable.dart';

final class TransferCommand extends Equatable {
  const TransferCommand({
    required this.actorId,
    required this.originId,
    required this.destinationId,
    required this.amountCop,
    this.description,
  });

  final int actorId;
  final int originId;
  final int destinationId;
  final int amountCop;
  final String? description;

  @override
  List<Object?> get props => [
    actorId,
    originId,
    destinationId,
    amountCop,
    description,
  ];
}
