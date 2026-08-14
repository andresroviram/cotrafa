import 'package:feature_auth/presentation/auth/bloc/auth_bloc.dart';
import 'package:feature_auth/presentation/auth/bloc/auth_event.dart';
import 'package:feature_auth/presentation/auth/bloc/auth_state.dart';
import 'package:feature_auth/presentation/login/view/login_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:responsive_framework/responsive_framework.dart';

final class _MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  setUpAll(() {
    registerFallbackValue(const AuthEvent.restoreRequested());
  });

  late _MockAuthBloc bloc;

  setUp(() {
    bloc = _MockAuthBloc();
    when(
      () => bloc.state,
    ).thenReturn(const AuthState(status: AuthStatus.unauthenticated));
    when(() => bloc.stream).thenAnswer((_) => const Stream<AuthState>.empty());
    when(() => bloc.add(any())).thenReturn(null);
  });

  Widget subject() => MaterialApp(
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF004183)),
    ),
    builder: (context, child) => ResponsiveBreakpoints.builder(
      child: child!,
      breakpoints: const [
        Breakpoint(start: 0, end: 450, name: MOBILE),
        Breakpoint(start: 451, end: double.infinity, name: DESKTOP),
      ],
    ),
    home: BlocProvider<AuthBloc>.value(
      value: bloc,
      child: const LoginView(
        authenticatedLocation: '/users',
        logoAssetPath: 'assets/img/logo.png',
        logoDarkAssetPath: 'assets/img/logo_dark.png',
      ),
    ),
  );

  Future<void> pumpSubject(WidgetTester tester) async {
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();
  }

  testWidgets('renders a minimal client login with a separate admin action', (
    tester,
  ) async {
    await pumpSubject(tester);

    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Bienvenido'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Activar cuenta'), findsOneWidget);
    expect(find.text('Iniciar como Admin'), findsOneWidget);
    expect(find.text('Correo o nombre de usuario'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.textContaining('credencial configurada'), findsNothing);
    expect(find.textContaining('Remember me'), findsNothing);
    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
  });

  testWidgets('opens the first-access activation route', (tester) async {
    final router = GoRouter(
      initialLocation: LoginView.path,
      routes: [
        GoRoute(
          path: LoginView.path,
          builder: (_, _) => BlocProvider<AuthBloc>.value(
            value: bloc,
            child: const LoginView(
              authenticatedLocation: '/users',
              logoAssetPath: 'assets/img/logo.png',
              logoDarkAssetPath: 'assets/img/logo_dark.png',
            ),
          ),
        ),
        GoRoute(
          path: '/activate',
          builder: (_, _) => const Scaffold(body: Text('Activation route')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        builder: (context, child) => ResponsiveBreakpoints.builder(
          child: child!,
          breakpoints: const [
            Breakpoint(start: 0, end: 450, name: MOBILE),
            Breakpoint(start: 451, end: double.infinity, name: DESKTOP),
          ],
        ),
      ),
    );

    await tester.ensureVisible(find.text('Activar cuenta'));
    await tester.tap(find.text('Activar cuenta'));
    await tester.pumpAndSettle();

    expect(find.text('Activation route'), findsOneWidget);
  });

  testWidgets('validates client credentials before dispatching login', (
    tester,
  ) async {
    await pumpSubject(tester);
    await tester.ensureVisible(find.text('Iniciar sesión'));
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pump();

    expect(find.text('Ingresa tu correo o nombre de usuario.'), findsOneWidget);
    expect(find.text('Ingresa tu contraseña.'), findsOneWidget);
    verifyNever(() => bloc.add(any()));
  });

  testWidgets('clears the password validation error while typing', (
    tester,
  ) async {
    await pumpSubject(tester);
    await tester.ensureVisible(find.text('Iniciar sesión'));
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pump();

    expect(find.text('Ingresa tu contraseña.'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(1), 'secret');
    await tester.pump();

    expect(find.text('Ingresa tu contraseña.'), findsNothing);
    expect(find.text('Ingresa tu correo o nombre de usuario.'), findsOneWidget);
  });

  testWidgets('dismisses the keyboard on outside tap but not while scrolling', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpSubject(tester);
    await tester.showKeyboard(find.byType(TextFormField).first);
    expect(tester.testTextInput.isVisible, isTrue);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(SingleChildScrollView)),
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

  testWidgets('dispatches client and injected demo login events', (
    tester,
  ) async {
    await pumpSubject(tester);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), ' CLIENT@EXAMPLE.COM ');
    await tester.enterText(fields.at(1), 'secret');
    await tester.ensureVisible(find.text('Iniciar sesión'));
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pump();

    verify(
      () => bloc.add(
        const AuthEvent.loginRequested('client@example.com', 'secret'),
      ),
    ).called(1);

    await tester.ensureVisible(find.text('Iniciar como Admin'));
    await tester.tap(find.text('Iniciar como Admin'));
    verify(() => bloc.add(const AuthEvent.demoAdminLoginRequested())).called(1);
  });
}
