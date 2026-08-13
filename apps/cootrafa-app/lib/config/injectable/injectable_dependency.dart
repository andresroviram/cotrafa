import 'package:cootrafa_app/config/injectable/injectable_dependency.config.dart';
import 'package:core/get_it.dart';
import 'package:core/injectable.module.dart';
import 'package:features/injectable.module.dart';
import 'package:injectable/injectable.dart';

@InjectableInit(
  externalPackageModulesBefore: [
    ExternalModule(CorePackageModule),
    ExternalModule(FeaturesPackageModule),
  ],
)
Future<void> configureDependencies() => getIt.init();
