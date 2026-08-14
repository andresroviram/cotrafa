import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_event.freezed.dart';

@freezed
sealed class UserEvent with _$UserEvent {
  const factory UserEvent.listRequested(int actorUserId) = UserListRequested;
  const factory UserEvent.profileRequested(int actorUserId, int userId) =
      UserProfileRequested;
  const factory UserEvent.searchChanged(String query) = UserSearchChanged;
  const factory UserEvent.createRequested(
    int actorUserId, {
    required String email,
    required int initialBalanceCop,
  }) = UserCreateRequested;
  const factory UserEvent.updateRequested(
    int actorUserId,
    int userId, {
    required String fullName,
  }) = UserUpdateRequested;
  const factory UserEvent.deleteRequested(int actorUserId, int userId) =
      UserDeleteRequested;
}
