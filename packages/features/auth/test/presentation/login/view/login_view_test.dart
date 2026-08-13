import 'package:feature_auth/presentation/auth/bloc/auth_bloc.dart';
import 'package:feature_auth/presentation/auth/bloc/auth_event.dart';
import 'package:feature_auth/presentation/auth/bloc/auth_state.dart';
import 'package:feature_auth/presentation/login/view/login_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

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
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00856A)),
    ),
    home: BlocProvider<AuthBloc>.value(
      value: bloc,
      child: const LoginView(authenticatedLocation: '/users'),
    ),
  );

  testWidgets(
    'renders demo and client access with the reference form language',
    (tester) async {
      await tester.pumpWidget(subject());

      expect(find.text('Cootrafa'), findsOneWidget);
      expect(find.text('Bienvenido'), findsOneWidget);
      expect(find.text('Iniciar sesión'), findsOneWidget);
      expect(find.text('Correo o nombre de usuario'), findsOneWidget);
      expect(find.text('Contraseña'), findsOneWidget);
      expect(find.text('Ingresar con mi cuenta'), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    },
  );

  testWidgets('validates client credentials before dispatching login', (
    tester,
  ) async {
    await tester.pumpWidget(subject());
    await tester.ensureVisible(find.text('Ingresar con mi cuenta'));
    await tester.tap(find.text('Ingresar con mi cuenta'));
    await tester.pump();

    expect(find.text('Ingresa tu correo o nombre de usuario.'), findsOneWidget);
    expect(find.text('Ingresa tu contraseña.'), findsOneWidget);
    verifyNever(() => bloc.add(any()));
  });

  testWidgets('dispatches client and injected demo login events', (
    tester,
  ) async {
    await tester.pumpWidget(subject());
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), ' CLIENT@EXAMPLE.COM ');
    await tester.enterText(fields.at(1), 'secret');
    await tester.ensureVisible(find.text('Ingresar con mi cuenta'));
    await tester.tap(find.text('Ingresar con mi cuenta'));
    await tester.pump();

    verify(
      () => bloc.add(
        const AuthEvent.loginRequested('client@example.com', 'secret'),
      ),
    ).called(1);

    await tester.ensureVisible(find.text('Iniciar sesión'));
    await tester.tap(find.text('Iniciar sesión'));
    verify(() => bloc.add(const AuthEvent.demoAdminLoginRequested())).called(1);
  });
}
