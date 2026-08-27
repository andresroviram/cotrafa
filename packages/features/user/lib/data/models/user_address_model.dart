import 'package:equatable/equatable.dart';
import 'package:feature_user/domain/entities/user_address.dart';

final class UserAddressModel extends Equatable {
  const UserAddressModel({
    required this.id,
    required this.userId,
    required this.line1,
    required this.line2,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    required this.label,
    required this.isPrimary,
  });

  final int id;
  final int userId;
  final String line1;
  final String? line2;
  final String city;
  final String? state;
  final String? postalCode;
  final String country;
  final String label;
  final bool isPrimary;

  @override
  List<Object?> get props => <Object?>[
    id,
    userId,
    line1,
    line2,
    city,
    state,
    postalCode,
    country,
    label,
    isPrimary,
  ];
}

extension UserAddressModelMapper on UserAddressModel {
  UserAddress toEntity() => UserAddress(
    id: id,
    userId: userId,
    line1: line1,
    line2: line2,
    city: city,
    state: state,
    postalCode: postalCode,
    country: country,
    label: label,
    isPrimary: isPrimary,
  );
}
