import 'package:feature_auth/presentation/activation/view/activation_view.dart';
import 'package:feature_auth/presentation/auth/bloc/auth_bloc.dart';
import 'package:feature_auth/presentation/auth/bloc/auth_event.dart';
import 'package:feature_auth/presentation/auth/bloc/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

final class _MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  setUpAll(() => registerFallbackValue(const AuthEvent.restoreRequested()));

  late _MockAuthBloc bloc;

  setUp(() {
    bloc = _MockAuthBloc();
    when(
      () => bloc.state,
    ).thenReturn(const AuthState(status: AuthStatus.unauthenticated));
    when(() => bloc.stream).thenAnswer((_) => const Stream<AuthState>.empty());
    when(() => bloc.add(any())).thenReturn(null);
  });

  Future<void> pumpSubject(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF004183)),
        ),
        home: BlocProvider<AuthBloc>.value(
          value: bloc,
          child: const ActivationView(
            authenticatedLocation: '/users',
            logoAssetPath: 'assets/img/logo.png',
            logoDarkAssetPath: 'assets/img/logo_dark.png',
          ),
        ),
      ),
    );
  }

  testWidgets('renders separate first-access credentials', (tester) async {
    await pumpSubject(tester);

    expect(find.text('Activa tu cuenta'), findsOneWidget);
    expect(find.byKey(const Key('activation-email')), findsOneWidget);
    expect(find.byKey(const Key('activation-code')), findsOneWidget);
    expect(find.byKey(const Key('activation-username')), findsOneWidget);
    expect(find.byKey(const Key('activation-password')), findsOneWidget);
    expect(find.text('Activar cuenta'), findsOneWidget);
  });

  testWidgets('validates and dispatches normalized activation data', (
    tester,
  ) async {
    await pumpSubject(tester);
    final submit = find.byKey(const Key('activate-account-submit'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();
    expect(find.text('Ingresa tu correo electrónico.'), findsOneWidget);
    expect(find.text('Ingresa el código de 6 dígitos.'), findsOneWidget);
    verifyNever(() => bloc.add(any()));

    await tester.enterText(
      find.byKey(const Key('activation-email')),
      ' SOFIA@COTRAFA.LOCAL ',
    );
    await tester.enterText(find.byKey(const Key('activation-code')), '123456');
    await tester.enterText(
      find.byKey(const Key('activation-username')),
      ' Sofia.User ',
    );
    await tester.enterText(
      find.byKey(const Key('activation-password')),
      'Secret123',
    );
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();

    verify(
      () => bloc.add(
        const AuthEvent.activationRequested(
          'sofia@cotrafa.local',
          '123456',
          'sofia.user',
          'Secret123',
        ),
      ),
    ).called(1);
  });
}
