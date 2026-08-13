import 'package:features/src/auth/domain/entities/demo_credentials.dart';
import 'package:injectable/injectable.dart';

@module
abstract class AuthModule {
  @singleton
  DemoCredentials get demoCredentials => DemoAdmin.credentials;
}
