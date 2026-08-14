import 'package:core/get_it.dart';
import 'package:feature_user/domain/entities/user_profile.dart';
import 'package:feature_user/presentation/users/bloc/user_bloc.dart';
import 'package:feature_user/presentation/users/bloc/user_event.dart';
import 'package:feature_user/presentation/users/bloc/user_state.dart';
import 'package:feature_user/presentation/user_edit/view/user_edit_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:responsive_framework/responsive_framework.dart';

final class _MockUserBloc extends Mock implements UserBloc {}

void main() {
  setUpAll(() => registerFallbackValue(const UserEvent.listRequested(0)));

  late _MockUserBloc bloc;

  setUp(() {
    bloc = _MockUserBloc();
    when(() => bloc.stream).thenAnswer((_) => const Stream<UserState>.empty());
    when(() => bloc.add(any())).thenReturn(null);
    when(() => bloc.close()).thenAnswer((_) async {});
  });

  tearDown(() async => getIt.reset());

  Widget app(Widget home) => MaterialApp(
    builder: (context, child) => ResponsiveBreakpoints.builder(
      child: child!,
      breakpoints: const [
        Breakpoint(start: 0, end: 450, name: MOBILE),
        Breakpoint(start: 451, end: double.infinity, name: DESKTOP),
      ],
    ),
    home: home,
  );

  testWidgets('loads the requested user when the full route opens', (
    tester,
  ) async {
    when(() => bloc.state).thenReturn(const UserState());
    getIt.registerFactory<UserBloc>(() => bloc);

    await tester.pumpWidget(
      app(UserEditView.create(actorUserId: 1, userId: 2)),
    );

    verify(() => bloc.add(const UserEvent.profileRequested(1, 2))).called(1);
  });

  testWidgets('edits profile data and keeps email and balance immutable', (
    tester,
  ) async {
    final user = UserProfile(
      id: 2,
      email: 'sofia@cotrafa.local',
      fullName: 'Sofia Rovira',
      firstName: 'Sofia',
      lastName: 'Rovira',
      birthDate: DateTime(2000, 6, 15),
      phone: '3000000000',
      role: 'client',
      status: 'active',
      balanceCop: 250000,
    );
    when(
      () => bloc.state,
    ).thenReturn(UserState(status: UserStatus.loaded, users: [user]));

    await tester.pumpWidget(
      app(
        BlocProvider<UserBloc>.value(
          value: bloc,
          child: const UserEditView(actorUserId: 1, userId: 2),
        ),
      ),
    );

    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.text('Editar usuario'), findsOneWidget);
    expect(
      tester
          .widget<SingleChildScrollView>(find.byType(SingleChildScrollView))
          .padding,
      const EdgeInsets.fromLTRB(24, 24, 24, 24),
    );
    final email = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('edit-user-email')),
        matching: find.byType(TextField),
      ),
    );
    expect(email.readOnly, isTrue);
    expect(email.controller?.text, user.email);
    expect(find.byKey(const Key('create-user-balance')), findsNothing);

    await tester.enterText(find.byKey(const Key('edit-user-first-name')), '');
    await tester.enterText(find.byKey(const Key('edit-user-last-name')), '');
    final submit = find.byKey(const Key('edit-user-submit'));
    expect(tester.state<FormState>(find.byType(Form)).validate(), isFalse);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('edit-user-first-name')),
      'Sofía',
    );
    await tester.enterText(
      find.byKey(const Key('edit-user-last-name')),
      'Rovira Gómez',
    );
    await tester.enterText(
      find.byKey(const Key('edit-user-phone')),
      '3012345678',
    );
    await tester.ensureVisible(submit);
    tester.widget<FilledButton>(submit).onPressed?.call();
    await tester.pump();

    verify(
      () => bloc.add(
        UserEvent.updateRequested(
          1,
          2,
          firstName: 'Sofía',
          lastName: 'Rovira Gómez',
          birthDate: DateTime(2000, 6, 15),
          phone: '3012345678',
        ),
      ),
    ).called(1);
  });

  testWidgets(
    'dismisses keyboard on outside tap but keeps it while scrolling',
    (tester) async {
      tester.view.physicalSize = const Size(400, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const user = UserProfile(
        id: 2,
        email: 'sofia@cotrafa.local',
        fullName: 'Sofia Rovira',
        firstName: 'Sofia',
        lastName: 'Rovira',
        role: 'client',
        status: 'active',
        balanceCop: 250000,
      );
      when(
        () => bloc.state,
      ).thenReturn(const UserState(status: UserStatus.loaded, users: [user]));

      await tester.pumpWidget(
        app(
          BlocProvider<UserBloc>.value(
            value: bloc,
            child: const UserEditView(actorUserId: 1, userId: 2),
          ),
        ),
      );
      final firstName = find.byKey(const Key('edit-user-first-name'));
      final lastName = find.byKey(const Key('edit-user-last-name'));
      await tester.showKeyboard(firstName);
      expect(tester.testTextInput.isVisible, isTrue);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(SingleChildScrollView)),
      );
      await gesture.moveBy(const Offset(0, -100));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.testTextInput.isVisible, isTrue);
      await gesture.up();
      await tester.pump();

      final gapY =
          (tester.getBottomLeft(firstName).dy +
              tester.getTopLeft(lastName).dy) /
          2;
      await tester.tapAt(Offset(200, gapY));
      await tester.pump();
      expect(tester.testTextInput.isVisible, isFalse);
    },
  );
}
