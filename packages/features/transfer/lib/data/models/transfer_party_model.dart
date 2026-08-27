import 'package:equatable/equatable.dart';
import 'package:feature_transfer/domain/entities/transfer_party.dart';

final class TransferPartyModel extends Equatable {
  const TransferPartyModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.balanceCop,
  });

  final int id;
  final String fullName;
  final String email;
  final int balanceCop;

  @override
  List<Object> get props => <Object>[id, fullName, email, balanceCop];
}

extension TransferPartyModelMapper on TransferPartyModel {
  TransferParty toEntity() => TransferParty(
    id: id,
    fullName: fullName,
    email: email,
    balanceCop: balanceCop,
  );
}
