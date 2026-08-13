import 'package:cootrafa_app/config/injectable/injectable_dependency.config.dart';
import 'package:cootrafa_database/injectable.module.dart';
import 'package:core/get_it.dart';
import 'package:core/injectable.module.dart';
import 'package:feature_auth/injectable.module.dart';
import 'package:feature_transfer/injectable.module.dart';
import 'package:feature_user/injectable.module.dart';
import 'package:injectable/injectable.dart';

@InjectableInit(
  externalPackageModulesBefore: [ExternalModule(CorePackageModule)],
  externalPackageModulesAfter: [
    ExternalModule(CootrafaDatabasePackageModule),
    ExternalModule(FeatureAuthPackageModule),
    ExternalModule(FeatureUserPackageModule),
    ExternalModule(FeatureTransferPackageModule),
  ],
)
Future<void> configureDependencies() => getIt.init();
