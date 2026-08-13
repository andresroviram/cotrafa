import 'package:feature_transfer/presentation/transfer/view/transfer_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final GlobalKey<NavigatorState> transferNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'transfer');

StatefulShellBranch get transferRoutes => StatefulShellBranch(
  navigatorKey: transferNavigatorKey,
  routes: [
    GoRoute(
      path: TransferView.path,
      name: TransferView.name,
      pageBuilder: (_, state) =>
          NoTransitionPage(key: state.pageKey, child: TransferView.create()),
    ),
  ],
);
