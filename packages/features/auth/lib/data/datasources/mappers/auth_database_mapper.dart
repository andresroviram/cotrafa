import 'package:cotrafa_database/cotrafa_database.dart';
import 'package:feature_auth/data/models/auth_identity_model.dart';

extension AuthUserDatabaseMapper on User {
  AuthIdentityModel toAuthIdentityModel() =>
      AuthIdentityModel(userId: id, role: role);
}
