import 'package:feature_user/domain/entities/user_profile.dart';
import 'package:feature_user/presentation/users/bloc/user_state.dart';
import 'package:feature_user/presentation/users/bloc/user_state_x.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const user = UserProfile(
    id: 2,
    email: 'sofia@cotrafa.local',
    fullName: 'Sofia Rovira',
    role: 'client',
    status: 'active',
    balanceCop: 250000,
  );

  String resolve(UserState state) => state.resolve(
    loading: () => 'loading',
    failure: (message) => 'failure:$message',
    empty: () => 'empty',
    data: (resolved) => 'data:${resolved.users.length}',
  );

  test('resolves initial, loading, failure, empty, and data consistently', () {
    expect(resolve(const UserState()), 'loading');
    expect(resolve(const UserState(status: UserStatus.loading)), 'loading');
    expect(
      resolve(
        const UserState(
          status: UserStatus.failure,
          message: 'Unable to load users.',
        ),
      ),
      'failure:Unable to load users.',
    );
    expect(resolve(const UserState(status: UserStatus.loaded)), 'empty');
    expect(
      resolve(const UserState(status: UserStatus.loaded, users: [user])),
      'data:1',
    );
  });

  test('keeps existing data visible during an action', () {
    expect(
      resolve(const UserState(status: UserStatus.loading, users: [user])),
      'data:1',
    );
  });
}
