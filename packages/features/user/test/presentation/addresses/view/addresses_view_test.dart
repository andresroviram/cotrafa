import 'dart:async';

import 'package:feature_user/domain/entities/user_address.dart';
import 'package:feature_user/presentation/addresses/bloc/address_bloc.dart';
import 'package:feature_user/presentation/addresses/bloc/address_event.dart';
import 'package:feature_user/presentation/addresses/bloc/address_state.dart';
import 'package:feature_user/presentation/addresses/view/addresses_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:responsive_framework/responsive_framework.dart';

final class _MockAddressBloc extends Mock implements AddressBloc {}

void main() {
  const address = UserAddress(
    id: 10,
    userId: 2,
    line1: 'Calle 10 # 20-30',
    line2: 'El Poblado',
    city: 'Medellín',
    state: 'Antioquia',
    postalCode: '050021',
    country: 'Colombia',
    label: 'Casa',
    isPrimary: true,
  );
  const secondary = UserAddress(
    id: 11,
    userId: 2,
    line1: 'Carrera 40 # 10-15',
    line2: null,
    city: 'Medellín',
    state: 'Antioquia',
    postalCode: null,
    country: 'Colombia',
    label: 'Trabajo',
    isPrimary: false,
  );

  late _MockAddressBloc bloc;

  setUpAll(() => registerFallbackValue(const AddressEvent.listRequested(0, 0)));

  setUp(() {
    bloc = _MockAddressBloc();
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => bloc.add(any())).thenReturn(null);
    when(() => bloc.close()).thenAnswer((_) async {});
  });

  Widget subject(AddressState state) {
    when(() => bloc.state).thenReturn(state);
    return MaterialApp(
      builder: (context, child) => ResponsiveBreakpoints.builder(
        child: child!,
        breakpoints: const [
          Breakpoint(start: 0, end: 450, name: MOBILE),
          Breakpoint(start: 451, end: double.infinity, name: DESKTOP),
        ],
      ),
      home: BlocProvider<AddressBloc>.value(
        value: bloc,
        child: const AddressesView(actorUserId: 1, userId: 2),
      ),
    );
  }

  testWidgets('renders the empty state and create action', (tester) async {
    await tester.pumpWidget(subject(const AddressState.loaded(addresses: [])));

    expect(find.text('Direcciones'), findsOneWidget);
    expect(find.text('No hay direcciones registradas'), findsOneWidget);
    expect(find.byKey(const Key('create-address-action')), findsOneWidget);
  });

  testWidgets('renders the reference address card hierarchy', (tester) async {
    await tester.pumpWidget(
      subject(const AddressState.loaded(addresses: [address])),
    );

    expect(find.byKey(const Key('address-card-10')), findsOneWidget);
    expect(find.text('Casa'), findsOneWidget);
    expect(find.text('Principal'), findsOneWidget);
    expect(find.text('Calle 10 # 20-30'), findsOneWidget);
    expect(find.text('El Poblado'), findsOneWidget);
    expect(find.text('Medellín, Antioquia, Colombia'), findsOneWidget);
    expect(find.text('CP: 050021'), findsOneWidget);
  });

  testWidgets(
    'refreshes addresses without dismissing through scroll behavior',
    (tester) async {
      final states = StreamController<AddressState>.broadcast();
      addTearDown(states.close);
      when(() => bloc.stream).thenAnswer((_) => states.stream);
      await tester.pumpWidget(
        subject(const AddressState.loaded(addresses: [address])),
      );

      final refresh = tester
          .widget<RefreshIndicator>(find.byType(RefreshIndicator))
          .onRefresh();

      verify(() => bloc.add(const AddressEvent.listRequested(1, 2))).called(1);
      states
        ..add(const AddressState.loading())
        ..add(const AddressState.loaded(addresses: [address]));
      await refresh;
      await tester.pumpAndSettle();
    },
  );

  testWidgets('dispatches primary selection and confirmed deletion', (
    tester,
  ) async {
    await tester.pumpWidget(
      subject(const AddressState.loaded(addresses: [address, secondary])),
    );

    await tester.tap(find.byKey(const Key('address-actions-11')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Marcar como principal'));
    await tester.pumpAndSettle();
    verify(
      () => bloc.add(const AddressEvent.primaryRequested(1, 2, 11)),
    ).called(1);

    await tester.tap(find.byKey(const Key('address-actions-11')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-delete-address')));
    await tester.pumpAndSettle();
    verify(
      () => bloc.add(const AddressEvent.deleteRequested(1, 2, 11)),
    ).called(1);
  });
}
