import 'package:core/errors/result.dart';
import 'package:feature_user/presentation/address_form/view/address_form_view.dart';
import 'package:feature_user/presentation/addresses/view/addresses_view.dart';
import 'package:feature_user/presentation/user_detail/view/user_detail_view.dart';
import 'package:feature_user/presentation/user_edit/view/user_edit_view.dart';
import 'package:feature_user/presentation/users/view/users_view.dart';
import 'package:feature_user/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  test('owns the users shell branch', () {
    final rootNavigatorKey = GlobalKey<NavigatorState>();
    final route =
        usersRoutes(
              parentNavigatorKey: rootNavigatorKey,
              actorUserId: () => 1,
              isAdmin: () => true,
              issueActivationCode: (_, _) async => const Success('123456'),
            ).routes.single
            as GoRoute;

    expect(route.path, UsersView.path);
    expect(route.name, UsersView.name);
    expect(route.routes, hasLength(2));
    final detailRoute = route.routes.first as GoRoute;
    expect(detailRoute.path, UserDetailView.path);
    expect(detailRoute.name, UserDetailView.name);
    expect(detailRoute.parentNavigatorKey, same(rootNavigatorKey));
    expect(detailRoute.routes, hasLength(1));
    final addressesRoute = detailRoute.routes.single as GoRoute;
    expect(addressesRoute.path, AddressesView.path);
    expect(addressesRoute.name, AddressesView.name);
    expect(addressesRoute.parentNavigatorKey, same(rootNavigatorKey));
    expect(addressesRoute.routes, hasLength(2));
    final createAddressRoute = addressesRoute.routes.first as GoRoute;
    expect(createAddressRoute.path, AddressFormView.createPath);
    expect(createAddressRoute.name, AddressFormView.createName);
    expect(createAddressRoute.parentNavigatorKey, same(rootNavigatorKey));
    final editAddressRoute = addressesRoute.routes.last as GoRoute;
    expect(editAddressRoute.path, AddressFormView.editPath);
    expect(editAddressRoute.name, AddressFormView.editName);
    expect(editAddressRoute.parentNavigatorKey, same(rootNavigatorKey));
    final editRoute = route.routes.last as GoRoute;
    expect(editRoute.path, UserEditView.path);
    expect(editRoute.name, UserEditView.name);
    expect(editRoute.parentNavigatorKey, same(rootNavigatorKey));
  });
}
