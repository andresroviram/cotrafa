import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_event.freezed.dart';

@freezed
sealed class AuthEvent with _$AuthEvent {
  const factory AuthEvent.restoreRequested() = AuthRestoreRequested;
  const factory AuthEvent.demoAdminLoginRequested() = DemoAdminLoginRequested;
  const factory AuthEvent.loginRequested(String identifier, String password) =
      AuthLoginRequested;
  const factory AuthEvent.activationRequested(
    String email,
    String code,
    String username,
    String password,
  ) = AuthActivationRequested;
  const factory AuthEvent.logoutRequested() = AuthLogoutRequested;
}
