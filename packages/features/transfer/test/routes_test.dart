import 'package:feature_transfer/presentation/transfer/view/transfer_create_view.dart';
import 'package:feature_transfer/presentation/transfer/view/transfer_result_view.dart';
import 'package:feature_transfer/presentation/transfer/view/transfer_view.dart';
import 'package:feature_transfer/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  test('owns the history branch and full-screen create route', () {
    final rootKey = GlobalKey<NavigatorState>();
    final route =
        transferRoutes(
              parentNavigatorKey: rootKey,
              actorUserId: () => 7,
              isAdmin: () => true,
            ).routes.single
            as GoRoute;

    expect(route.path, TransferView.path);
    expect(route.name, TransferView.name);
    final create = route.routes.whereType<GoRoute>().singleWhere(
      (child) => child.name == TransferCreateView.name,
    );
    expect(create.path, TransferCreateView.path);
    expect(create.name, TransferCreateView.name);
    expect(create.parentNavigatorKey, same(rootKey));
    final result = route.routes.whereType<GoRoute>().singleWhere(
      (child) => child.name == TransferResultView.name,
    );
    expect(result.path, TransferResultView.path);
    expect(result.parentNavigatorKey, same(rootKey));
  });
}
