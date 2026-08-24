final class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    this.username,
    this.firstName,
    this.lastName,
    this.birthDate,
    this.phone,
    required this.role,
    required this.status,
    required this.balanceCop,
  });

  final int id;
  final String email;
  final String fullName;
  final String? username;
  final String? firstName;
  final String? lastName;
  final DateTime? birthDate;
  final String? phone;
  final String role;
  final String status;
  final int balanceCop;

  String get displayName {
    final personalName = <String?>[firstName, lastName]
        .whereType<String>()
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .join(' ');
    if (personalName.isNotEmpty) return personalName;
    if (fullName.trim().isNotEmpty) return fullName.trim();
    return email;
  }

  String get initials => displayName
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0].toUpperCase())
      .join();

  int? ageAt(DateTime referenceDate) {
    final date = birthDate;
    if (date == null) return null;
    var age = referenceDate.year - date.year;
    if (referenceDate.month < date.month ||
        (referenceDate.month == date.month && referenceDate.day < date.day)) {
      age--;
    }
    return age;
  }
}
