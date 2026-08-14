import 'dart:async';

import 'package:feature_transfer/domain/entities/transfer_party.dart';
import 'package:feature_transfer/domain/entities/transfer_receipt.dart';
import 'package:feature_transfer/presentation/transfer/bloc/transfer_bloc.dart';
import 'package:feature_transfer/presentation/transfer/bloc/transfer_event.dart';
import 'package:feature_transfer/presentation/transfer/bloc/transfer_state.dart';
import 'package:feature_transfer/presentation/transfer/view/transfer_create_view.dart';
import 'package:feature_transfer/presentation/transfer/view/transfer_result_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:responsive_framework/responsive_framework.dart';

final class _MockTransferBloc extends Mock implements TransferBloc {}

void main() {
  const party = TransferParty(
    id: 2,
    fullName: 'Origin',
    email: 'origin@test.co',
    balanceCop: 500,
  );
  const receipt = TransferReceipt(
    id: 'transfer-1',
    originUserId: 2,
    destinationUserId: 3,
    amountCop: 100,
    status: 'completed',
    description: null,
    createdAt: 1,
    originSnapshot: 'Origin',
    destinationSnapshot: 'Destination',
  );

  late _MockTransferBloc bloc;
  late StreamController<TransferState> states;
  late TransferState current;
  late GoRouter router;

  setUpAll(() => registerFallbackValue(const TransferEvent.loadRequested(0)));

  setUp(() {
    current = const TransferState(
      status: TransferStatus.loaded,
      parties: [party],
    );
    states = StreamController<TransferState>.broadcast();
    bloc = _MockTransferBloc();
    when(() => bloc.state).thenAnswer((_) => current);
    when(() => bloc.stream).thenAnswer((_) => states.stream);
    when(() => bloc.add(any())).thenReturn(null);
    when(() => bloc.close()).thenAnswer((_) async {});
    router = GoRouter(
      initialLocation: '/create',
      routes: [
        GoRoute(
          path: '/create',
          builder: (_, _) => BlocProvider<TransferBloc>.value(
            value: bloc,
            child: const TransferCreateView(actorUserId: 2, isAdmin: false),
          ),
        ),
        GoRoute(
          path: '/result',
          name: TransferResultView.name,
          builder: (_, state) =>
              TransferResultView(outcome: state.extra! as TransferOutcome),
        ),
      ],
    );
  });

  tearDown(() async {
    router.dispose();
    await states.close();
  });

  Widget subject() => MaterialApp.router(
    builder: (context, child) => ResponsiveBreakpoints.builder(
      child: child!,
      breakpoints: const [
        Breakpoint(start: 0, end: 450, name: MOBILE),
        Breakpoint(start: 451, end: double.infinity, name: DESKTOP),
      ],
    ),
    routerConfig: router,
  );

  Future<void> emit(WidgetTester tester, TransferState state) async {
    current = state;
    states.add(state);
    await tester.pump();
  }

  testWidgets('opens the independent success result screen', (tester) async {
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    await emit(
      tester,
      const TransferState(status: TransferStatus.submitting, parties: [party]),
    );
    await emit(
      tester,
      const TransferState(
        status: TransferStatus.completed,
        parties: [party],
        receipt: receipt,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('transfer-result-success')), findsOneWidget);
    expect(find.byKey(const Key('transfer-create-content')), findsNothing);
  });

  testWidgets('opens the independent failure result screen', (tester) async {
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    await emit(
      tester,
      const TransferState(status: TransferStatus.submitting, parties: [party]),
    );
    await emit(
      tester,
      const TransferState(
        status: TransferStatus.failure,
        parties: [party],
        message: 'Saldo insuficiente.',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('transfer-result-failure')), findsOneWidget);
    expect(find.text('Saldo insuficiente.'), findsOneWidget);
    expect(find.byKey(const Key('transfer-create-content')), findsNothing);
  });
}
