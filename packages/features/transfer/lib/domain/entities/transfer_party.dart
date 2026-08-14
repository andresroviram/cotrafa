import 'package:equatable/equatable.dart';

final class TransferParty extends Equatable {
  const TransferParty({
    required this.id,
    required this.fullName,
    required this.email,
    required this.balanceCop,
  });

  final int id;
  final String fullName;
  final String email;
  final int balanceCop;

  String get displayName => fullName.trim().isEmpty ? email : fullName;

  @override
  List<Object> get props => [id, fullName, email, balanceCop];
}
