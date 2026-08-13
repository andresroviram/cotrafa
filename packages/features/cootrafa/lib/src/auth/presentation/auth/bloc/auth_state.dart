import 'package:features/src/auth/domain/entities/auth_identity.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_state.freezed.dart';

enum AuthStatus {
  initial,
  loading,
  unauthenticated,
  authenticated,
  activationSuccess,
  failure,
}

@freezed
abstract class AuthState with _$AuthState {
  const factory AuthState({
    @Default(AuthStatus.initial) AuthStatus status,
    AuthIdentity? identity,
    String? message,
  }) = _AuthState;
}
