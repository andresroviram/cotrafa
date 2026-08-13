import 'package:feature_auth/presentation/login/view/login_view.dart';
import 'package:go_router/go_router.dart';

GoRoute loginRoute({required String authenticatedLocation}) => GoRoute(
  path: LoginView.path,
  name: LoginView.name,
  builder: (_, _) =>
      LoginView.create(authenticatedLocation: authenticatedLocation),
);
