import 'package:feature_user/domain/entities/delete_outcome.dart';
import 'package:feature_user/domain/entities/user_profile.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_state.freezed.dart';

@freezed
sealed class UserState with _$UserState {
  const factory UserState.initial({
    @Default(<UserProfile>[]) List<UserProfile> users,
    @Default('') String searchQuery,
  }) = UserInitial;

  const factory UserState.loading({
    @Default(<UserProfile>[]) List<UserProfile> users,
    @Default('') String searchQuery,
  }) = UserLoading;

  const factory UserState.loaded({
    @Default(<UserProfile>[]) List<UserProfile> users,
    @Default('') String searchQuery,
  }) = UserLoaded;

  const factory UserState.created({
    required List<UserProfile> users,
    @Default('') String searchQuery,
  }) = UserCreated;

  const factory UserState.updated({
    required List<UserProfile> users,
    @Default('') String searchQuery,
  }) = UserUpdated;

  const factory UserState.deleted({
    required List<UserProfile> users,
    required DeleteOutcome deleteOutcome,
    @Default('') String searchQuery,
  }) = UserDeleted;

  const factory UserState.information({
    required String message,
    @Default(<UserProfile>[]) List<UserProfile> users,
    @Default('') String searchQuery,
  }) = UserInformation;

  const factory UserState.failure({
    required String message,
    @Default(<UserProfile>[]) List<UserProfile> users,
    @Default('') String searchQuery,
  }) = UserFailure;
}
