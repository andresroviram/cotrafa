import 'package:feature_auth/domain/entities/auth_identity.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_state.freezed.dart';

@freezed
sealed class AuthState with _$AuthState {
  const factory AuthState.initial() = AuthInitial;
  const factory AuthState.loading() = AuthLoading;
  const factory AuthState.unauthenticated() = AuthUnauthenticated;
  const factory AuthState.authenticated(AuthIdentity identity) =
      AuthAuthenticated;
  const factory AuthState.activationSuccess(AuthIdentity identity) =
      AuthActivationSuccess;
  const factory AuthState.failure(String message) = AuthStateFailure;
}
