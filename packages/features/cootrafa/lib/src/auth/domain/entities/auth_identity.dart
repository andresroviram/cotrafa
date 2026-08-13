import 'package:equatable/equatable.dart';

final class AuthIdentity extends Equatable {
  const AuthIdentity({required this.userId, required this.role});
  final int userId;
  final String role;
  @override
  List<Object> get props => <Object>[userId, role];
}
