import 'package:feature_auth/presentation/activation/view/activation_view.dart';
import 'package:feature_auth/presentation/login/view/login_view.dart';
import 'package:go_router/go_router.dart';

GoRoute loginRoute({
  required String authenticatedLocation,
  required String logoAssetPath,
  required String logoDarkAssetPath,
}) => GoRoute(
  path: LoginView.path,
  name: LoginView.name,
  builder: (_, _) => LoginView.create(
    authenticatedLocation: authenticatedLocation,
    logoAssetPath: logoAssetPath,
    logoDarkAssetPath: logoDarkAssetPath,
  ),
);

GoRoute activationRoute({
  required String authenticatedLocation,
  required String logoAssetPath,
  required String logoDarkAssetPath,
}) => GoRoute(
  path: ActivationView.path,
  name: ActivationView.name,
  builder: (_, _) => ActivationView.create(
    authenticatedLocation: authenticatedLocation,
    logoAssetPath: logoAssetPath,
    logoDarkAssetPath: logoDarkAssetPath,
  ),
);
