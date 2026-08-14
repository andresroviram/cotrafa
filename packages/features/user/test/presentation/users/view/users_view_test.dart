import 'dart:async';

import 'package:bot_toast/bot_toast.dart';
import 'package:core/get_it.dart';
import 'package:feature_user/domain/entities/delete_outcome.dart';
import 'package:feature_user/domain/entities/user_profile.dart';
import 'package:feature_user/presentation/users/bloc/user_bloc.dart';
import 'package:feature_user/presentation/users/bloc/user_event.dart';
import 'package:feature_user/presentation/users/bloc/user_state.dart';
import 'package:feature_user/presentation/users/view/user_detail_view.dart';
import 'package:feature_user/presentation/users/view/users_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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
    final theme = ThemeData.from(colorScheme: colors, useMaterial3: true)
        .copyWith(
          scaffoldBackgroundColor: colors.surfaceContainerLow,
          cardTheme: CardThemeData(color: colors.surface),
          inputDecorationTheme: InputDecorationThemeData(
            filled: true,
            fillColor: brightness == Brightness.light
                ? colors.surface
                : colors.surfaceContainerHighest,
          ),
        );
    return MaterialApp(
      key: key,
      theme: theme,
      navigatorObservers: [BotToastNavigatorObserver()],
      builder: (context, child) => BotToastInit()(
        context,
        ResponsiveBreakpoints.builder(
          child: child!,
          breakpoints: const [
            Breakpoint(start: 0, end: 450, name: MOBILE),
            Breakpoint(start: 451, end: double.infinity, name: DESKTOP),
          ],
        ),
      ),
      home: home,
    );
  }

  Widget subject(
    UserState state, {
    int actorUserId = 1,
    Brightness brightness = Brightness.light,
    bool isAdmin = true,
    Future<String?> Function(int, String)? issueActivationCode,
  }) {
    when(() => bloc.state).thenReturn(state);
    return app(
      BlocProvider<UserBloc>.value(
        value: bloc,
        child: UsersView(
          actorUserId: actorUserId,
          isAdmin: isAdmin,
          issueActivationCode: issueActivationCode,
        ),
      ),
      key: ValueKey((state, brightness)),
      brightness: brightness,
    );
  }

  Widget routedApp(GoRouter router) => MaterialApp.router(
    routerConfig: router,
    builder: (context, child) => BotToastInit()(
      context,
      ResponsiveBreakpoints.builder(
        child: child!,
        breakpoints: const [
          Breakpoint(start: 0, end: 450, name: MOBILE),
          Breakpoint(start: 451, end: double.infinity, name: DESKTOP),
        ],
      ),
    ),
  );

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

  testWidgets('reloads users when the navigation shell returns to its branch', (
    tester,
  ) async {
    when(
      () => bloc.state,
    ).thenReturn(const UserState(status: UserStatus.loaded));
    late StatefulNavigationShell navigationShell;
    final router = GoRouter(
      initialLocation: '/users',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (_, _, shell) {
            navigationShell = shell;
            return Scaffold(
              body: shell,
              bottomNavigationBar: Row(
                children: [
                  TextButton(
                    key: const Key('open-users-branch'),
                    onPressed: () =>
                        navigationShell.goBranch(0, initialLocation: true),
                    child: const Text('Usuarios'),
                  ),
                  TextButton(
                    key: const Key('open-transfer-branch'),
                    onPressed: () =>
                        navigationShell.goBranch(1, initialLocation: true),
                    child: const Text('Transferencias'),
                  ),
                ],
              ),
            );
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/users',
                  builder: (_, _) => BlocProvider<UserBloc>.value(
                    value: bloc,
                    child: const UsersView(actorUserId: 1, isAdmin: true),
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/transfer',
                  builder: (_, _) => const Scaffold(
                    body: Center(child: Text('Transferencias')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(routedApp(router));
    await tester.pumpAndSettle();
    clearInteractions(bloc);

    await tester.tap(find.byKey(const Key('open-transfer-branch')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-users-branch')));
    await tester.pumpAndSettle();

    verify(() => bloc.add(const UserEvent.listRequested(1))).called(1);
  });

  testWidgets('renders Cotrafa data using the reference card hierarchy', (
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
              email: 'client@cotrafa.test',
              fullName: 'Sofia Rovira',
              role: 'client',
              status: 'pendingActivation',
              balanceCop: 250000,
            ),
            UserProfile(
              id: 3,
              email: 'andres@cotrafa.test',
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
    expect(tester.widget<Card>(find.byType(Card)).color, isNull);
    expect(
      Theme.of(tester.element(find.byType(Card))).cardTheme.color,
      Colors.white,
    );
    expect(find.text('SR'), findsOneWidget);
    expect(find.text('Sofia Rovira'), findsOneWidget);
    expect(find.text('Andres Perez'), findsNothing);
    expect(find.text('client@cotrafa.test'), findsOneWidget);
    expect(find.text('Pendiente de activación'), findsOneWidget);
    expect(find.textContaining('250.000'), findsOneWidget);
    final statusLabel = tester.widget<DecoratedBox>(
      find
          .ancestor(
            of: find.text('Pendiente de activación'),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    expect(
      (statusLabel.decoration as BoxDecoration).color,
      Theme.of(tester.element(find.byType(Card))).colorScheme.primaryContainer,
    );

    final searchField = tester.widget<TextField>(
      find.byKey(const Key('user-search-field')),
    );
    searchField.onChanged?.call('client');
    verify(() => bloc.add(const UserEvent.searchChanged('client'))).called(1);

    final cardRect = tester.getRect(find.byType(Card));
    final menu = find.byKey(const Key('user-actions-2'));
    final menuRect = tester.getRect(menu);
    expect((menuRect.top - cardRect.top).abs(), lessThanOrEqualTo(4));
    expect((menuRect.right - cardRect.right).abs(), lessThanOrEqualTo(4));
    final menuButton = tester.widget<PopupMenuButton<Object?>>(menu);
    expect(menuButton.offset, const Offset(0, 40));
  });

  testWidgets('refreshes below the search field with pull to refresh', (
    tester,
  ) async {
    final states = StreamController<UserState>.broadcast();
    addTearDown(states.close);
    when(() => bloc.stream).thenAnswer((_) => states.stream);
    const state = UserState(
      status: UserStatus.loaded,
      users: [
        UserProfile(
          id: 2,
          email: 'client@cotrafa.test',
          fullName: 'Sofia Rovira',
          role: 'client',
          status: 'active',
          balanceCop: 250000,
        ),
      ],
    );

    await tester.pumpWidget(subject(state));
    clearInteractions(bloc);

    expect(find.byIcon(Icons.refresh), findsNothing);
    expect(find.byTooltip('Actualizar usuarios'), findsNothing);
    final refresh = find.byKey(const Key('user-refresh-indicator'));
    expect(refresh, findsOneWidget);
    expect(
      tester.getTopLeft(refresh).dy,
      greaterThanOrEqualTo(
        tester.getBottomLeft(find.byKey(const Key('user-search-field'))).dy,
      ),
    );

    final refreshCompleted = tester
        .widget<RefreshIndicator>(refresh)
        .onRefresh();
    verify(() => bloc.add(const UserEvent.listRequested(1))).called(1);

    states
      ..add(state.copyWith(status: UserStatus.loading))
      ..add(state);
    await refreshCompleted;
    await tester.pumpAndSettle();
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
          email: 'client@cotrafa.test',
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
    expect(tester.widget<Card>(find.byType(Card)).color, isNull);
    expect(Theme.of(context).cardTheme.color, colors.surface);
    final search = tester.widget<TextField>(
      find.byKey(const Key('user-search-field')),
    );
    expect(search.decoration?.fillColor, isNull);
    expect(
      Theme.of(context).inputDecorationTheme.fillColor,
      colors.surfaceContainerHighest,
    );
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
              email: 'client@cotrafa.test',
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

    final listTopLeft = tester.getTopLeft(find.byType(ListView));
    await tester.tapAt(listTopLeft + const Offset(4, 4));
    await tester.pump();
    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('admin creates a client and receives an activation code', (
    tester,
  ) async {
    final states = StreamController<UserState>.broadcast();
    addTearDown(states.close);
    when(() => bloc.stream).thenAnswer((_) => states.stream);

    var issuedForActor = 0;
    var issuedForEmail = '';
    await tester.pumpWidget(
      subject(
        const UserState(status: UserStatus.loaded),
        issueActivationCode: (actorUserId, email) async {
          issuedForActor = actorUserId;
          issuedForEmail = email;
          return '123456';
        },
      ),
    );

    await tester.tap(find.byKey(const Key('create-user-action')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('create-user-first-name')),
      'Sofia',
    );
    await tester.enterText(
      find.byKey(const Key('create-user-last-name')),
      'Rovira',
    );
    await tester.enterText(
      find.byKey(const Key('create-user-email')),
      'sofia@cotrafa.local',
    );
    await tester.enterText(
      find.byKey(const Key('create-user-balance')),
      '250000',
    );
    await tester.tap(find.byKey(const Key('create-user-submit')));
    await tester.pump();

    verify(
      () => bloc.add(
        const UserEvent.createRequested(
          1,
          email: 'sofia@cotrafa.local',
          firstName: 'Sofia',
          lastName: 'Rovira',
          birthDate: null,
          phone: null,
          initialBalanceCop: 250000,
        ),
      ),
    ).called(1);

    states.add(
      const UserState(
        status: UserStatus.created,
        users: [
          UserProfile(
            id: 2,
            email: 'sofia@cotrafa.local',
            fullName: 'Sofia Rovira',
            firstName: 'Sofia',
            lastName: 'Rovira',
            role: 'client',
            status: 'pendingActivation',
            balanceCop: 250000,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('123456'), findsOneWidget);
    expect(issuedForActor, 1);
    expect(issuedForEmail, 'sofia@cotrafa.local');

    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('create-user-submit')), findsNothing);
  });

  testWidgets('requires first and last name when creating a client', (
    tester,
  ) async {
    await tester.pumpWidget(
      subject(
        const UserState(status: UserStatus.loaded),
        issueActivationCode: (_, _) async => '123456',
      ),
    );

    await tester.tap(find.byKey(const Key('create-user-action')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('create-user-email')),
      'client@cotrafa.local',
    );
    await tester.tap(find.byKey(const Key('create-user-submit')));
    await tester.pump();

    expect(find.text('Ingresa el nombre'), findsOneWidget);
    expect(find.text('Ingresa el apellido'), findsOneWidget);
    verifyNever(() => bloc.add(any()));
  });

  testWidgets('opens detail from the card and edit from the action menu', (
    tester,
  ) async {
    const user = UserProfile(
      id: 2,
      email: 'sofia@cotrafa.local',
      fullName: 'Sofia Rovira',
      role: 'client',
      status: 'active',
      balanceCop: 250000,
    );
    when(
      () => bloc.state,
    ).thenReturn(const UserState(status: UserStatus.loaded, users: [user]));
    final router = GoRouter(
      initialLocation: '/users',
      routes: [
        GoRoute(
          path: '/users',
          builder: (_, _) => BlocProvider<UserBloc>.value(
            value: bloc,
            child: const UsersView(actorUserId: 1, isAdmin: true),
          ),
          routes: [
            GoRoute(
              path: ':userId',
              name: UserDetailView.name,
              builder: (_, state) => Scaffold(
                body: Text('Detalle usuario ${state.pathParameters['userId']}'),
              ),
            ),
            GoRoute(
              path: ':userId/edit',
              name: 'edit-user',
              builder: (_, state) => Scaffold(
                body: Text('Editar usuario ${state.pathParameters['userId']}'),
              ),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(routedApp(router));
    clearInteractions(bloc);

    await tester.tap(find.text('Sofia Rovira'));
    await tester.pumpAndSettle();
    expect(find.text('Detalle usuario 2'), findsOneWidget);

    router.pop();
    await tester.pumpAndSettle();
    verify(() => bloc.add(const UserEvent.listRequested(1))).called(1);
    await tester.tap(find.byKey(const Key('user-actions-2')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('edit-user-2')), findsOneWidget);
    expect(find.widgetWithIcon(Row, Icons.edit_outlined), findsOneWidget);
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    expect(find.text('Editar usuario 2'), findsOneWidget);
  });

  testWidgets('admin regenerates the code for a pending client', (
    tester,
  ) async {
    var issuedForActor = 0;
    var issuedForEmail = '';
    await tester.pumpWidget(
      subject(
        const UserState(
          status: UserStatus.loaded,
          users: [
            UserProfile(
              id: 2,
              email: 'sofia@cotrafa.local',
              fullName: 'Sofia Rovira',
              role: 'client',
              status: 'pendingActivation',
              balanceCop: 250000,
            ),
          ],
        ),
        issueActivationCode: (actorUserId, email) async {
          issuedForActor = actorUserId;
          issuedForEmail = email;
          return '654321';
        },
      ),
    );

    await tester.tap(find.byKey(const Key('user-actions-2')));
    await tester.pumpAndSettle();
    final codeAction = find.ancestor(
      of: find.text('Generar nuevo código'),
      matching: find.byType(InkWell),
    );
    await tester.tap(codeAction.first);
    await tester.pumpAndSettle();

    expect(find.text('654321'), findsOneWidget);
    expect(issuedForActor, 1);
    expect(issuedForEmail, 'sofia@cotrafa.local');
  });

  testWidgets('activation-code failures are delegated to the view listener', (
    tester,
  ) async {
    await tester.pumpWidget(
      subject(
        const UserState(
          status: UserStatus.loaded,
          users: [
            UserProfile(
              id: 2,
              email: 'sofia@cotrafa.local',
              fullName: 'Sofia Rovira',
              role: 'client',
              status: 'pendingActivation',
              balanceCop: 250000,
            ),
          ],
        ),
        issueActivationCode: (_, _) async => null,
      ),
    );
    clearInteractions(bloc);

    await tester.tap(find.byKey(const Key('user-actions-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Generar nuevo código'));
    await tester.pumpAndSettle();

    verify(
      () => bloc.add(
        const UserEvent.notificationRequested('No pudimos generar el código'),
      ),
    ).called(1);
  });

  testWidgets('admin confirms user deletion from the action menu', (
    tester,
  ) async {
    final states = StreamController<UserState>.broadcast();
    addTearDown(states.close);
    when(() => bloc.stream).thenAnswer((_) => states.stream);
    const user = UserProfile(
      id: 2,
      email: 'sofia@cotrafa.local',
      fullName: 'Sofia Rovira',
      role: 'client',
      status: 'active',
      balanceCop: 250000,
    );
    await tester.pumpWidget(
      subject(const UserState(status: UserStatus.loaded, users: [user])),
    );
    clearInteractions(bloc);

    await tester.tap(find.byKey(const Key('user-actions-2')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('delete-user-2')), findsOneWidget);
    expect(find.widgetWithIcon(Row, Icons.delete_outline), findsOneWidget);

    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();
    expect(find.text('Eliminar usuario'), findsOneWidget);
    expect(
      find.textContaining('se desactivará para conservar el historial'),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
    await tester.pumpAndSettle();
    verifyNever(() => bloc.add(const UserEvent.deleteRequested(1, 2)));

    await tester.tap(find.byKey(const Key('user-actions-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Eliminar'));
    await tester.pump();

    verify(() => bloc.add(const UserEvent.deleteRequested(1, 2))).called(1);
    states
      ..add(const UserState(status: UserStatus.loading, users: [user]))
      ..add(
        const UserState(
          status: UserStatus.deleted,
          deleteOutcome: DeleteOutcome.deactivated,
        ),
      );
    await tester.pumpAndSettle();

    expect(
      find.text('Usuario desactivado para conservar el historial'),
      findsOneWidget,
    );
  });

  testWidgets('client edits only itself without admin actions', (tester) async {
    await tester.pumpWidget(
      subject(
        const UserState(
          status: UserStatus.loaded,
          users: [
            UserProfile(
              id: 2,
              email: 'sofia@cotrafa.local',
              fullName: 'Sofia Rovira',
              role: 'client',
              status: 'pendingActivation',
              balanceCop: 250000,
            ),
            UserProfile(
              id: 3,
              email: 'another@cotrafa.local',
              fullName: 'Another Client',
              role: 'client',
              status: 'active',
              balanceCop: 0,
            ),
          ],
        ),
        actorUserId: 2,
        isAdmin: false,
      ),
    );

    expect(find.byKey(const Key('create-user-action')), findsNothing);
    expect(find.byKey(const Key('regenerate-code-2')), findsNothing);
    expect(find.byKey(const Key('user-actions-2')), findsOneWidget);
    expect(find.byKey(const Key('user-actions-3')), findsNothing);
    await tester.tap(find.byKey(const Key('user-actions-2')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('delete-user-2')), findsNothing);
  });
}
