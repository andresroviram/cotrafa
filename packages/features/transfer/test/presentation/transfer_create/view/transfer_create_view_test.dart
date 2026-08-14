import 'package:feature_transfer/domain/entities/transfer_party.dart';
import 'package:feature_transfer/presentation/transfer/bloc/transfer_bloc.dart';
import 'package:feature_transfer/presentation/transfer/bloc/transfer_event.dart';
import 'package:feature_transfer/presentation/transfer/bloc/transfer_state.dart';
import 'package:feature_transfer/presentation/transfer_create/view/transfer_create_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:responsive_framework/responsive_framework.dart';

final class _MockTransferBloc extends Mock implements TransferBloc {}

void main() {
  const origin = TransferParty(
    id: 2,
    fullName: 'Origin User',
    email: 'origin@test.co',
    balanceCop: 500000,
  );
  const destination = TransferParty(
    id: 3,
    fullName: 'Destination User',
    email: 'destination@test.co',
    balanceCop: 100000,
  );

  late _MockTransferBloc bloc;

  setUpAll(() {
    registerFallbackValue(const TransferEvent.loadRequested(0));
  });

  setUp(() {
    bloc = _MockTransferBloc();
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => bloc.add(any())).thenReturn(null);
  });

  Widget subject(TransferState state, {bool isAdmin = false}) {
    when(() => bloc.state).thenReturn(state);
    return MaterialApp(
      builder: (context, child) => ResponsiveBreakpoints.builder(
        child: child!,
        breakpoints: const [
          Breakpoint(start: 0, end: 450, name: MOBILE),
          Breakpoint(start: 451, end: double.infinity, name: DESKTOP),
        ],
      ),
      home: BlocProvider<TransferBloc>.value(
        value: bloc,
        child: TransferCreateView(actorUserId: 2, isAdmin: isAdmin),
      ),
    );
  }

  Future<void> pumpLoaded(WidgetTester tester, {bool isAdmin = false}) async {
    await tester.pumpWidget(
      subject(
        const TransferState(
          status: TransferStatus.loaded,
          parties: [origin, destination],
        ),
        isAdmin: isAdmin,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders the client transfer form', (tester) async {
    await pumpLoaded(tester);

    expect(find.text('Nueva transferencia'), findsOneWidget);
    expect(find.byKey(const Key('transfer-client-origin')), findsOneWidget);
    expect(find.textContaining('Origin User'), findsOneWidget);
    expect(find.text('Usuario destino'), findsOneWidget);
    expect(find.byKey(const Key('transfer-amount')), findsOneWidget);
    expect(find.byKey(const Key('transfer-description')), findsOneWidget);
    expect(find.text('Transferir'), findsOneWidget);
  });

  testWidgets('validates and dispatches normalized transfer data', (
    tester,
  ) async {
    await pumpLoaded(tester);
    final submit = find.byKey(const Key('transfer-submit'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();
    expect(find.text('Selecciona el usuario destino.'), findsOneWidget);
    expect(find.text('Ingresa un valor válido.'), findsOneWidget);
    verifyNever(() => bloc.add(any()));

    final destinationField = find.byType(DropdownButtonFormField<int>);
    await tester.tap(destinationField);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Destination User').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('transfer-amount')), '250000');
    await tester.enterText(
      find.byKey(const Key('transfer-description')),
      ' Payment ',
    );
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();

    verify(
      () => bloc.add(
        const TransferEvent.createRequested(
          actorUserId: 2,
          originUserId: 2,
          destinationUserId: 3,
          amountCop: 250000,
          description: ' Payment ',
        ),
      ),
    ).called(1);
  });

  testWidgets('keeps the keyboard while scrolling and dismisses on tap', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpLoaded(tester);
    final amount = find.byKey(const Key('transfer-amount'));
    await tester.showKeyboard(amount);
    expect(tester.testTextInput.isVisible, isTrue);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(SingleChildScrollView)),
    );
    await gesture.moveBy(const Offset(0, -100));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.testTextInput.isVisible, isTrue);
    await gesture.up();
    await tester.pump();

    await tester.tapAt(const Offset(12, 220));
    await tester.pump();
    expect(tester.testTextInput.isVisible, isFalse);
  });
}
