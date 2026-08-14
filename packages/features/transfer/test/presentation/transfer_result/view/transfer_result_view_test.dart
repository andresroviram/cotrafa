import 'package:feature_transfer/domain/entities/transfer_receipt.dart';
import 'package:feature_transfer/presentation/transfer_result/transfer_outcome.dart';
import 'package:feature_transfer/presentation/transfer_result/view/transfer_result_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_framework/responsive_framework.dart';

void main() {
  const receipt = TransferReceipt(
    id: 'transfer-1',
    originUserId: 2,
    destinationUserId: 3,
    amountCop: 250000,
    status: 'completed',
    description: 'Payment',
    createdAt: 1,
    originSnapshot: 'Origin User <origin@test.co>',
    destinationSnapshot: 'Destination User <destination@test.co>',
  );

  Widget subject(TransferOutcome outcome) => MaterialApp(
    builder: (context, child) => ResponsiveBreakpoints.builder(
      child: child!,
      breakpoints: const [
        Breakpoint(start: 0, end: 450, name: MOBILE),
        Breakpoint(start: 451, end: double.infinity, name: DESKTOP),
      ],
    ),
    home: TransferResultView(outcome: outcome),
  );

  testWidgets('shows the successful receipt widget', (tester) async {
    await tester.pumpWidget(subject(const TransferOutcome.success(receipt)));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('transfer-result-success')), findsOneWidget);
    expect(find.text('Transferencia exitosa'), findsOneWidget);
    expect(find.byKey(const Key('transfer-receipt')), findsOneWidget);
    expect(find.text('transfer-1'), findsOneWidget);
    expect(find.text('Volver al historial'), findsOneWidget);
    expect(find.byKey(const Key('transfer-result-failure')), findsNothing);
  });

  testWidgets('shows the failed transfer widget', (tester) async {
    await tester.pumpWidget(
      subject(const TransferOutcome.failure('Saldo insuficiente.')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('transfer-result-failure')), findsOneWidget);
    expect(find.text('Transferencia fallida'), findsOneWidget);
    expect(find.text('Saldo insuficiente.'), findsOneWidget);
    expect(find.text('Intentar nuevamente'), findsOneWidget);
    expect(find.text('Volver al historial'), findsOneWidget);
    expect(find.byKey(const Key('transfer-result-success')), findsNothing);
  });
}
