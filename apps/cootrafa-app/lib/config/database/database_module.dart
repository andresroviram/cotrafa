import 'package:cootrafa_database/cootrafa_database.dart';
import 'package:core/security/credential_hasher.dart';
import 'package:feature_auth/domain/entities/demo_credentials.dart';
import 'package:injectable/injectable.dart';

@module
abstract class DatabaseModule {
  @singleton
  CootrafaDatabase database(CredentialHasher credentialHasher) =>
      CootrafaDatabase(
        credentialHasher,
        seed: const CootrafaDatabaseSeed(
          userId: DemoAdmin.userId,
          email: DemoAdmin.email,
          fullName: DemoAdmin.fullName,
          password: DemoAdmin.password,
        ),
      );
}
