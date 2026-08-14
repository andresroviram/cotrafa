import 'dart:async';

import 'package:cotrafa_app/app.dart';
import 'package:cotrafa_app/config/routes/app_router.dart';
import 'package:core/get_it.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feature_auth/domain/entities/auth_identity.dart';
import 'package:feature_auth/presentation/auth/bloc/auth_bloc.dart';
import 'package:feature_auth/presentation/auth/bloc/auth_event.dart';
import 'package:feature_auth/presentation/auth/bloc/auth_state.dart';
import 'package:feature_transfer/presentation/transfer/bloc/transfer_history_bloc.dart';
import 'package:feature_transfer/presentation/transfer/bloc/transfer_history_event.dart';
import 'package:feature_transfer/presentation/transfer/bloc/transfer_history_state.dart';
import 'package:feature_user/presentation/users/bloc/user_bloc.dart';
import 'package:feature_user/presentation/users/bloc/user_event.dart';
import 'package:feature_user/presentation/users/bloc/user_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

final class MockAuthBloc extends Mock implements AuthBloc {}

final class MockUserBloc extends Mock implements UserBloc {}

final class MockTransferHistoryBloc extends Mock
    implements TransferHistoryBloc {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    registerFallbackValue(const UserEvent.listRequested(0));
    registerFallbackValue(const TransferHistoryEvent.loadRequested(0));
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('logout action returns the authenticated shell to login', (
    tester,
  ) async {
    var currentState = const AuthState(
      status: AuthStatus.authenticated,
      identity: AuthIdentity(userId: 1, role: 'admin'),
    );
    final states = StreamController<AuthState>.broadcast();
    final authBloc = MockAuthBloc();
    when(() => authBloc.state).thenAnswer((_) => currentState);
    when(() => authBloc.stream).thenAnswer((_) => states.stream);
    when(() => authBloc.add(const AuthEvent.logoutRequested())).thenAnswer((_) {
      currentState = const AuthState(status: AuthStatus.loading);
      states.add(currentState);
      currentState = const AuthState(status: AuthStatus.unauthenticated);
      states.add(currentState);
    });
    final userBloc = MockUserBloc();
    when(
      () => userBloc.state,
    ).thenReturn(const UserState(status: UserStatus.loaded));
    when(
      () => userBloc.stream,
    ).thenAnswer((_) => const Stream<UserState>.empty());
    when(() => userBloc.add(any())).thenReturn(null);
    when(() => userBloc.close()).thenAnswer((_) async {});
    final transferBloc = MockTransferHistoryBloc();
    when(() => transferBloc.state).thenReturn(
      const TransferHistoryState(status: TransferHistoryStatus.loaded),
    );
    when(
      () => transferBloc.stream,
    ).thenAnswer((_) => const Stream<TransferHistoryState>.empty());
    when(() => transferBloc.add(any())).thenReturn(null);
    when(() => transferBloc.close()).thenAnswer((_) async {});

    final router = createRouter(authBloc);
    getIt
      ..registerSingleton<AuthBloc>(authBloc)
      ..registerFactory<UserBloc>(() => userBloc)
      ..registerFactory<TransferHistoryBloc>(() => transferBloc)
      ..registerSingleton<GoRouter>(router);
    addTearDown(() async {
      await states.close();
      router.dispose();
      await getIt.reset();
    });

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('es'), Locale('en')],
        path: 'assets/translations',
        fallbackLocale: const Locale('es'),
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Cerrar sesión'), findsOneWidget);
    await tester.tap(find.byTooltip('Cerrar sesión'));
    await tester.pumpAndSettle();

    verify(() => authBloc.add(const AuthEvent.logoutRequested())).called(1);
    expect(find.byTooltip('Cerrar sesión'), findsNothing);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
