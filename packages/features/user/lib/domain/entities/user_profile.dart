final class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.status,
    required this.balanceCop,
  });

  final int id;
  final String email;
  final String fullName;
  final String role;
  final String status;
  final int balanceCop;
}
