import 'package:feature_transfer/presentation/transfer_create/view/transfer_create_view.dart';
import 'package:feature_transfer/presentation/transfer_result/transfer_outcome.dart';
import 'package:feature_transfer/presentation/transfer_result/view/transfer_result_view.dart';
import 'package:feature_transfer/presentation/transfer/view/transfer_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final GlobalKey<NavigatorState> transferNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'transfer');

StatefulShellBranch transferRoutes({
  required GlobalKey<NavigatorState> parentNavigatorKey,
  required int Function() actorUserId,
  required bool Function() isAdmin,
}) => StatefulShellBranch(
  navigatorKey: transferNavigatorKey,
  routes: [
    GoRoute(
      path: TransferView.path,
      name: TransferView.name,
      pageBuilder: (_, state) {
        final currentActorUserId = actorUserId();
        return NoTransitionPage(
          key: ValueKey('${state.pageKey}-$currentActorUserId'),
          child: TransferView.create(actorUserId: currentActorUserId),
        );
      },
      routes: [
        GoRoute(
          path: TransferCreateView.path,
          name: TransferCreateView.name,
          parentNavigatorKey: parentNavigatorKey,
          builder: (_, _) => TransferCreateView.create(
            actorUserId: actorUserId(),
            isAdmin: isAdmin(),
          ),
        ),
        GoRoute(
          path: TransferResultView.path,
          name: TransferResultView.name,
          parentNavigatorKey: parentNavigatorKey,
          builder: (_, state) => TransferResultView(
            outcome: switch (state.extra) {
              final TransferOutcome outcome => outcome,
              _ => const TransferOutcome.failure(
                'No fue posible recuperar el resultado.',
              ),
            },
          ),
        ),
      ],
    ),
  ],
);
