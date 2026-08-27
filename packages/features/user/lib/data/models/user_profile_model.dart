import 'package:equatable/equatable.dart';
import 'package:feature_user/domain/entities/user_profile.dart';

final class UserProfileModel extends Equatable {
  const UserProfileModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.username,
    this.firstName,
    this.lastName,
    this.birthDate,
    this.phone,
    required this.role,
    required this.status,
    required this.balanceCop,
  });

  final int id;
  final String email;
  final String fullName;
  final String? username;
  final String? firstName;
  final String? lastName;
  final DateTime? birthDate;
  final String? phone;
  final String role;
  final String status;
  final int balanceCop;

  @override
  List<Object?> get props => <Object?>[
    id,
    email,
    fullName,
    username,
    firstName,
    lastName,
    birthDate,
    phone,
    role,
    status,
    balanceCop,
  ];
}

extension UserProfileModelMapper on UserProfileModel {
  UserProfile toEntity() => UserProfile(
    id: id,
    email: email,
    fullName: fullName,
    username: username,
    firstName: firstName,
    lastName: lastName,
    birthDate: birthDate,
    phone: phone,
    role: role,
    status: status,
    balanceCop: balanceCop,
  );
}
