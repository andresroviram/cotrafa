import 'package:cotrafa_database/cotrafa_database.dart';
import 'package:feature_user/data/models/user_address_model.dart';
import 'package:feature_user/data/models/user_profile_model.dart';

extension UserProfileDatabaseMapper on User {
  UserProfileModel toUserProfileModel({String? username}) => UserProfileModel(
    id: id,
    email: email,
    fullName: fullName,
    username: username,
    firstName: firstName,
    lastName: lastName,
    birthDate: switch (birthDate) {
      final milliseconds? => DateTime.fromMillisecondsSinceEpoch(
        milliseconds,
        isUtc: true,
      ),
      null => null,
    },
    phone: phone,
    role: role,
    status: status,
    balanceCop: balanceCop,
  );
}

extension UserAddressDatabaseMapper on AddressesData {
  UserAddressModel toUserAddressModel() => UserAddressModel(
    id: id,
    userId: userId,
    line1: line1,
    line2: line2,
    city: city,
    state: state,
    postalCode: postalCode,
    country: country ?? 'Colombia',
    label: label,
    isPrimary: isPrimary,
  );
}
