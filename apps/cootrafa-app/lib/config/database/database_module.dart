import 'package:cootrafa_app/config/database/cootrafa_database.dart';
import 'package:core/security/credential_hasher.dart';
import 'package:injectable/injectable.dart';

@module
abstract class DatabaseModule {
  @singleton
  CootrafaDatabase database(CredentialHasher credentialHasher) =>
      CootrafaDatabase(credentialHasher);
}
