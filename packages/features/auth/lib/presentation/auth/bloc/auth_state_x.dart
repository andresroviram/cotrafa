import 'package:feature_auth/presentation/auth/bloc/auth_state.dart';

extension AuthStateX on AuthState {
  bool get isLoading => status == AuthStatus.loading;

  bool get hasFailure => status == AuthStatus.failure && message != null;

  T resolve<T>({
    required T Function() loading,
    required T Function(String message) failure,
    required T Function(AuthState state) data,
  }) {
    if (isLoading) return loading();
    if (hasFailure) return failure(message!);
    return data(this);
  }
}
