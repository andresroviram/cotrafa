import 'package:feature_auth/presentation/auth/bloc/auth_state.dart';
import 'package:feature_auth/presentation/auth/bloc/auth_state_x.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String resolve(AuthState state) => state.resolve(
    loading: () => 'loading',
    failure: (message) => 'failure:$message',
    data: (resolved) => 'data:${resolved.status.name}',
  );

  test('resolves loading, failure, and interactive states consistently', () {
    expect(resolve(const AuthState()), 'data:initial');
    expect(
      resolve(const AuthState(status: AuthStatus.unauthenticated)),
      'data:unauthenticated',
    );
    expect(resolve(const AuthState(status: AuthStatus.loading)), 'loading');
    expect(
      resolve(
        const AuthState(
          status: AuthStatus.failure,
          message: 'Unable to sign in.',
        ),
      ),
      'failure:Unable to sign in.',
    );
  });
}
