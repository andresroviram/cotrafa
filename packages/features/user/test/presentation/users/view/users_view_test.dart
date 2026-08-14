import 'package:core/get_it.dart';
import 'package:feature_user/domain/entities/user_profile.dart';
import 'package:feature_user/presentation/users/bloc/user_bloc.dart';
import 'package:feature_user/presentation/users/bloc/user_event.dart';
import 'package:feature_user/presentation/users/bloc/user_state.dart';
import 'package:feature_user/presentation/users/view/users_view.dart';
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

  Widget app(
    Widget home, {
    Key? key,
    Brightness brightness = Brightness.light,
  }) {
    final generatedColors = ColorScheme.fromSeed(
      seedColor: const Color(0xFF004183),
      brightness: brightness,
    );
    final colors = brightness == Brightness.light
        ? generatedColors.copyWith(surface: Colors.white)
        : generatedColors;
    return MaterialApp(
      key: key,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colors,
        scaffoldBackgroundColor: colors.surfaceContainerLow,
        cardTheme: CardThemeData(color: colors.surface),
      ),
      builder: (_, child) => ResponsiveBreakpoints.builder(
        child: child!,
        breakpoints: const [
          Breakpoint(start: 0, end: 450, name: MOBILE),
          Breakpoint(start: 451, end: double.infinity, name: DESKTOP),
        ],
      ),
      home: home,
    );
  }

  Widget subject(UserState state, {Brightness brightness = Brightness.light}) {
    when(() => bloc.state).thenReturn(state);
    return app(
      BlocProvider<UserBloc>.value(
        value: bloc,
        child: const UsersView(actorUserId: 1, isAdmin: true),
      ),
      key: ValueKey((state, brightness)),
      brightness: brightness,
    );
  }

  testWidgets('loads the correct scope from the authenticated actor', (
    tester,
  ) async {
    when(() => bloc.state).thenReturn(const UserState());
    getIt.registerFactory<UserBloc>(() => bloc);

    await tester.pumpWidget(
      app(UsersView.create(actorUserId: 7, isAdmin: true)),
    );
    verify(() => bloc.add(const UserEvent.listRequested(7))).called(1);

    await tester.pumpWidget(const SizedBox());
    clearInteractions(bloc);
    await tester.pumpWidget(
      app(UsersView.create(actorUserId: 8, isAdmin: false)),
    );
    verify(() => bloc.add(const UserEvent.profileRequested(8, 8))).called(1);
  });

  testWidgets('renders Cootrafa data using the reference card hierarchy', (
    tester,
  ) async {
    await tester.pumpWidget(
      subject(
        const UserState(
          status: UserStatus.loaded,
          searchQuery: 'sofia',
          users: [
            UserProfile(
              id: 2,
              email: 'client@cootrafa.test',
              fullName: 'Sofia Rovira',
              role: 'client',
              status: 'pendingActivation',
              balanceCop: 250000,
            ),
            UserProfile(
              id: 3,
              email: 'andres@cootrafa.test',
              fullName: 'Andres Perez',
              role: 'client',
              status: 'active',
              balanceCop: 100000,
            ),
          ],
        ),
      ),
    );

    expect(find.text('Lista de usuarios'), findsOneWidget);
    expect(tester.widget<Card>(find.byType(Card)).color, Colors.white);
    expect(find.text('SR'), findsOneWidget);
    expect(find.text('Sofia Rovira'), findsOneWidget);
    expect(find.text('Andres Perez'), findsNothing);
    expect(find.text('client@cootrafa.test'), findsOneWidget);
    expect(find.text('Pendiente de activación'), findsOneWidget);
    expect(find.textContaining('250.000'), findsOneWidget);

    final searchField = tester.widget<TextField>(
      find.byKey(const Key('user-search-field')),
    );
    searchField.onChanged?.call('client');
    verify(() => bloc.add(const UserEvent.searchChanged('client'))).called(1);
  });

  testWidgets('exposes empty, failure, and retry states', (tester) async {
    await tester.pumpWidget(
      subject(const UserState(status: UserStatus.loaded)),
    );
    expect(find.text('Aún no hay usuarios'), findsOneWidget);

    await tester.pumpWidget(
      subject(
        const UserState(
          status: UserStatus.failure,
          message: 'Unable to load users.',
        ),
      ),
    );
    expect(find.text('No pudimos cargar los usuarios'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    verify(() => bloc.add(const UserEvent.listRequested(1))).called(1);
  });

  testWidgets('uses native dark surfaces for cards and search', (tester) async {
    const state = UserState(
      status: UserStatus.loaded,
      users: [
        UserProfile(
          id: 2,
          email: 'client@cootrafa.test',
          fullName: 'Sofia Rovira',
          role: 'client',
          status: 'active',
          balanceCop: 250000,
        ),
      ],
    );

    await tester.pumpWidget(subject(state, brightness: Brightness.dark));

    final context = tester.element(find.byType(Card));
    final colors = Theme.of(context).colorScheme;
    expect(tester.widget<Card>(find.byType(Card)).color, colors.surface);
    final search = tester.widget<TextField>(
      find.byKey(const Key('user-search-field')),
    );
    expect(search.decoration?.fillColor, colors.surfaceContainerHighest);
  });

  testWidgets('dismisses search keyboard on tap but not sustained scroll', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      subject(
        const UserState(
          status: UserStatus.loaded,
          users: [
            UserProfile(
              id: 2,
              email: 'client@cootrafa.test',
              fullName: 'Sofia Rovira',
              role: 'client',
              status: 'active',
              balanceCop: 250000,
            ),
          ],
        ),
      ),
    );
    await tester.showKeyboard(find.byKey(const Key('user-search-field')));
    expect(tester.testTextInput.isVisible, isTrue);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(ListView)),
    );
    await gesture.moveBy(const Offset(0, -100));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.testTextInput.isVisible, isTrue);
    await gesture.up();
    await tester.pump();

    await tester.tapAt(const Offset(10, 10));
    await tester.pump();
    expect(tester.testTextInput.isVisible, isFalse);
  });
}
