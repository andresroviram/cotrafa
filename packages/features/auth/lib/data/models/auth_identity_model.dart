import 'package:equatable/equatable.dart';
import 'package:feature_auth/domain/entities/auth_identity.dart';

final class AuthIdentityModel extends Equatable {
  const AuthIdentityModel({required this.userId, required this.role});

  final int userId;
  final String role;

  @override
  List<Object> get props => <Object>[userId, role];
}

extension AuthIdentityModelMapper on AuthIdentityModel {
  AuthIdentity toEntity() => AuthIdentity(userId: userId, role: role);
}
