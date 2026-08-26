import 'dart:async';

import 'package:feature_transfer/domain/entities/transfer_receipt.dart';
import 'package:feature_transfer/presentation/transfer/bloc/transfer_history_bloc.dart';
import 'package:feature_transfer/presentation/transfer/bloc/transfer_history_event.dart';
import 'package:feature_transfer/presentation/transfer/bloc/transfer_history_state.dart';
import 'package:feature_transfer/presentation/transfer/view/transfer_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:responsive_framework/responsive_framework.dart';

final class _MockTransferHistoryBloc extends Mock
    implements TransferHistoryBloc {}

void main() {
  const outgoing = TransferReceipt(
    id: 'transfer-1',
    originUserId: 2,
    destinationUserId: 3,
    amountCop: 250000,
    status: 'completed',
    description: 'Payment',
    createdAt: 2,
    originSnapshot: 'Origin User <origin@test.co>',
    destinationSnapshot: 'Destination User <destination@test.co>',
  );
  const incoming = TransferReceipt(
    id: 'transfer-2',
    originUserId: 3,
    destinationUserId: 2,
    amountCop: 100000,
    status: 'completed',
    description: null,
    createdAt: 1,
    originSnapshot: 'Destination User <destination@test.co>',
    destinationSnapshot: 'Origin User <origin@test.co>',
  );

  late _MockTransferHistoryBloc bloc;

  setUpAll(() {
    registerFallbackValue(const TransferHistoryEvent.loadRequested(0));
  });

  setUp(() {
    bloc = _MockTransferHistoryBloc();
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => bloc.add(any())).thenReturn(null);
  });

  Widget subject(TransferHistoryState state) {
    when(() => bloc.state).thenReturn(state);
    return MaterialApp(
      locale: const Locale('es'),
      supportedLocales: const [Locale('es'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) => ResponsiveBreakpoints.builder(
        child: child!,
        breakpoints: const [
          Breakpoint(start: 0, end: 450, name: MOBILE),
          Breakpoint(start: 451, end: double.infinity, name: DESKTOP),
        ],
      ),
      home: BlocProvider<TransferHistoryBloc>.value(
        value: bloc,
        child: const TransferView(actorUserId: 2),
      ),
    );
  }

  testWidgets('renders the empty history and transfer action', (tester) async {
    await tester.pumpWidget(
      subject(const TransferHistoryState.loaded(transfers: [])),
    );
    await tester.pumpAndSettle();

    expect(find.text('Transferencias'), findsOneWidget);
    expect(find.text('Aún no hay transferencias.'), findsOneWidget);
    expect(find.byKey(const Key('transfer-create-fab')), findsOneWidget);
  });

  testWidgets('renders incoming and outgoing operations newest first', (
    tester,
  ) async {
    await tester.pumpWidget(
      subject(
        const TransferHistoryState.loaded(transfers: [outgoing, incoming]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('transfer-history-list')), findsOneWidget);
    expect(find.text('Enviada'), findsOneWidget);
    expect(find.text('Recibida'), findsOneWidget);
    expect(find.textContaining('250.000'), findsOneWidget);
    expect(find.textContaining('100.000'), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const Key('transfer-card-transfer-1'))).dy,
      lessThan(
        tester.getTopLeft(find.byKey(const Key('transfer-card-transfer-2'))).dy,
      ),
    );
  });

  testWidgets('refreshes the actor history', (tester) async {
    await tester.pumpWidget(
      subject(const TransferHistoryState.loaded(transfers: [])),
    );
    await tester.pumpAndSettle();

    unawaited(
      tester.state<RefreshIndicatorState>(find.byType(RefreshIndicator)).show(),
    );
    await tester.pumpAndSettle();

    verify(
      () => bloc.add(const TransferHistoryEvent.loadRequested(2)),
    ).called(1);
  });
}
