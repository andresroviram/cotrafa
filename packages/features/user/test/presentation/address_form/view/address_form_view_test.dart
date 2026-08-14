import 'package:feature_user/domain/entities/user_address.dart';
import 'package:feature_user/presentation/address_form/view/address_form_view.dart';
import 'package:feature_user/presentation/addresses/bloc/address_bloc.dart';
import 'package:feature_user/presentation/addresses/bloc/address_event.dart';
import 'package:feature_user/presentation/addresses/bloc/address_state.dart';
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

  late _MockAddressBloc bloc;

  setUpAll(() => registerFallbackValue(const AddressEvent.listRequested(0, 0)));

  setUp(() {
    bloc = _MockAddressBloc();
    when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => bloc.add(any())).thenReturn(null);
    when(() => bloc.close()).thenAnswer((_) async {});
  });

  Widget subject(AddressState state, {int? addressId}) {
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
        child: AddressFormView(actorUserId: 1, userId: 2, addressId: addressId),
      ),
    );
  }

  testWidgets('validates and dispatches a new address', (tester) async {
    await tester.pumpWidget(
      subject(const AddressState(status: AddressStatus.ready)),
    );

    expect(find.text('Nueva dirección'), findsOneWidget);
    final line1 = find.byKey(const Key('address-line-1'));
    await tester.showKeyboard(line1);
    await tester.enterText(line1, ' Calle 10 # 20-30 ');
    await tester.enterText(
      find.byKey(const Key('address-line-2')),
      ' El Poblado ',
    );
    await tester.enterText(find.byKey(const Key('address-city')), ' Medellín ');
    await tester.enterText(
      find.byKey(const Key('address-state')),
      ' Antioquia ',
    );
    await tester.enterText(
      find.byKey(const Key('address-postal-code')),
      '050021',
    );
    await tester.ensureVisible(find.byKey(const Key('address-submit')));
    tester
        .widget<FilledButton>(find.byKey(const Key('address-submit')))
        .onPressed!();
    await tester.pump();

    verify(
      () => bloc.add(
        const AddressEvent.createRequested(
          1,
          2,
          AddressDraft(
            line1: 'Calle 10 # 20-30',
            line2: 'El Poblado',
            city: 'Medellín',
            state: 'Antioquia',
            postalCode: '050021',
            country: 'Colombia',
            label: 'Casa',
          ),
        ),
      ),
    ).called(1);
  });

  testWidgets('preloads and dispatches address edits', (tester) async {
    await tester.pumpWidget(
      subject(
        const AddressState(
          status: AddressStatus.ready,
          addresses: [address],
          selectedAddress: address,
        ),
        addressId: 10,
      ),
    );

    expect(find.text('Editar dirección'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('address-line-1')))
          .controller
          ?.text,
      'Calle 10 # 20-30',
    );
    await tester.ensureVisible(find.byKey(const Key('address-submit')));
    tester
        .widget<FilledButton>(find.byKey(const Key('address-submit')))
        .onPressed!();
    await tester.pump();

    verify(
      () => bloc.add(
        const AddressEvent.updateRequested(
          1,
          2,
          10,
          AddressDraft(
            line1: 'Calle 10 # 20-30',
            line2: 'El Poblado',
            city: 'Medellín',
            state: 'Antioquia',
            postalCode: '050021',
            country: 'Colombia',
            label: 'Casa',
          ),
        ),
      ),
    ).called(1);
  });

  testWidgets('keeps keyboard on scroll and dismisses it on outside tap', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      subject(const AddressState(status: AddressStatus.ready)),
    );
    final line1 = find.byKey(const Key('address-line-1'));
    await tester.showKeyboard(line1);
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
