import 'package:feature_user/domain/entities/delete_outcome.dart';
import 'package:feature_user/domain/entities/user_profile.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_state.freezed.dart';

enum UserStatus { initial, loading, loaded, created, updated, deleted, failure }

@freezed
abstract class UserState with _$UserState {
  const factory UserState({
    @Default(UserStatus.initial) UserStatus status,
    @Default(<UserProfile>[]) List<UserProfile> users,
    @Default('') String searchQuery,
    DeleteOutcome? deleteOutcome,
    String? message,
  }) = _UserState;
}
