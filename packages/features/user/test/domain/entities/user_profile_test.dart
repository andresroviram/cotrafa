import 'package:feature_user/domain/entities/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'derives display name, initials, and age from optional profile data',
    () {
      final profile = UserProfile(
        id: 2,
        email: 'sofia@cotrafa.local',
        fullName: 'Legacy name',
        firstName: 'Sofia',
        lastName: 'Rovira',
        birthDate: DateTime(2000, 8, 14),
        phone: '3001234567',
        role: 'client',
        status: 'active',
        balanceCop: 0,
      );

      expect(profile.displayName, 'Sofia Rovira');
      expect(profile.initials, 'SR');
      expect(profile.ageAt(DateTime(2026, 8, 13)), 25);
    },
  );

  test('falls back safely when optional profile data is missing', () {
    const profile = UserProfile(
      id: 2,
      email: 'client@cotrafa.local',
      fullName: '',
      role: 'client',
      status: 'pendingActivation',
      balanceCop: 0,
    );

    expect(profile.displayName, 'client@cotrafa.local');
    expect(profile.initials, 'C');
    expect(profile.ageAt(DateTime(2026, 8, 13)), isNull);
  });
}
