import 'package:feature_user/presentation/users/bloc/user_state.dart';

extension UserStateX on UserState {
  bool get isLoading =>
      (status == UserStatus.initial || status == UserStatus.loading) &&
      users.isEmpty;

  bool get hasFailure =>
      status == UserStatus.failure && message != null && users.isEmpty;

  T resolve<T>({
    required T Function() loading,
    required T Function(String message) failure,
    required T Function(UserState state) data,
    T Function()? empty,
  }) {
    if (isLoading) return loading();
    if (hasFailure) return failure(message!);
    if (users.isEmpty) return empty?.call() ?? data(this);
    return data(this);
  }
}
