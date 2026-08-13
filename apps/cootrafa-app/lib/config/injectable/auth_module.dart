import 'package:features/auth.dart';
import 'package:injectable/injectable.dart';

@module
abstract class AuthModule {
  @singleton
  DemoCredentials get demoCredentials => DemoAdmin.credentials;
}
