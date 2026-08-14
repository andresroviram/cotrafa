final class UserAddress {
  const UserAddress({
    required this.id,
    required this.userId,
    required this.line1,
    required this.line2,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    required this.label,
    required this.isPrimary,
  });

  final int id;
  final int userId;
  final String line1;
  final String? line2;
  final String city;
  final String? state;
  final String? postalCode;
  final String country;
  final String label;
  final bool isPrimary;

  UserAddress copyWith({bool? isPrimary}) => UserAddress(
    id: id,
    userId: userId,
    line1: line1,
    line2: line2,
    city: city,
    state: state,
    postalCode: postalCode,
    country: country,
    label: label,
    isPrimary: isPrimary ?? this.isPrimary,
  );

  String get location => <String?>[city, state, country]
      .whereType<String>()
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .join(', ');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAddress &&
          id == other.id &&
          userId == other.userId &&
          line1 == other.line1 &&
          line2 == other.line2 &&
          city == other.city &&
          state == other.state &&
          postalCode == other.postalCode &&
          country == other.country &&
          label == other.label &&
          isPrimary == other.isPrimary;

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    line1,
    line2,
    city,
    state,
    postalCode,
    country,
    label,
    isPrimary,
  );
}

final class AddressDraft {
  const AddressDraft({
    required this.line1,
    required this.line2,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    required this.label,
  });

  final String line1;
  final String? line2;
  final String city;
  final String? state;
  final String? postalCode;
  final String country;
  final String label;
}
