import 'package:cotrafa_app/config/env/app_flavor.dart';
import 'package:core/env/i_env_config.dart';
import 'package:envied/envied.dart';
import 'package:injectable/injectable.dart';

part 'env.g.dart';

@Envied(path: '.env.dev', useConstantCase: true, name: 'EnvDev')
final class EnvDev {
  @EnviedField(varName: 'API_KEY', obfuscate: true, defaultValue: '')
  static final String apiKey = _EnvDev.apiKey;
  @EnviedField(
    varName: 'BASE_URL',
    obfuscate: true,
    defaultValue: 'http://localhost:3000',
  )
  static final String baseUrl = _EnvDev.baseUrl;
}

@Envied(path: '.env.qa', useConstantCase: true, name: 'EnvQa')
final class EnvQa {
  @EnviedField(varName: 'API_KEY', obfuscate: true, defaultValue: '')
  static final String apiKey = _EnvQa.apiKey;
  @EnviedField(
    varName: 'BASE_URL',
    obfuscate: true,
    defaultValue: 'http://localhost:3000',
  )
  static final String baseUrl = _EnvQa.baseUrl;
}

@Envied(path: '.env.prod', useConstantCase: true, name: 'EnvProd')
final class EnvProd {
  @EnviedField(varName: 'API_KEY', obfuscate: true, defaultValue: '')
  static final String apiKey = _EnvProd.apiKey;
  @EnviedField(
    varName: 'BASE_URL',
    obfuscate: true,
    defaultValue: 'http://localhost:3000',
  )
  static final String baseUrl = _EnvProd.baseUrl;
}

@LazySingleton(as: IEnvConfig)
final class Env implements IEnvConfig {
  Env() : _flavor = kFlavor;

  final AppFlavor _flavor;

  @override
  String? get apiKey => switch (_flavor) {
    AppFlavor.dev => EnvDev.apiKey,
    AppFlavor.qa => EnvQa.apiKey,
    AppFlavor.prod => EnvProd.apiKey,
  };

  @override
  String get baseUrl => switch (_flavor) {
    AppFlavor.dev => EnvDev.baseUrl,
    AppFlavor.qa => EnvQa.baseUrl,
    AppFlavor.prod => EnvProd.baseUrl,
  };
}
