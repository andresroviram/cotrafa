import 'dart:convert';
import 'dart:io';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:cotrafa_app/app.dart';
import 'package:cotrafa_app/config/routes/app_router.dart';
import 'package:core/get_it.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feature_auth/presentation/auth/bloc/auth_bloc.dart';
import 'package:feature_auth/presentation/auth/bloc/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

final class MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    await EasyLocalization.ensureInitialized();
  });

  test('uses the correct Cotrafa brand in every supported locale', () {
    for (final locale in ['es', 'en']) {
      final translation =
          jsonDecode(
                File('assets/translations/$locale.json').readAsStringSync(),
              )
              as Map<String, Object?>;

      expect(translation['app_title'], 'Cotrafa');
    }
  });

  testWidgets('starts on the login screen in light adaptive mode', (
    tester,
  ) async {
    final authBloc = MockAuthBloc();
    when(
      () => authBloc.state,
    ).thenReturn(const AuthState(status: AuthStatus.unauthenticated));
    when(
      () => authBloc.stream,
    ).thenAnswer((_) => const Stream<AuthState>.empty());
    final router = createRouter(authBloc);
    getIt
      ..registerSingleton<AuthBloc>(authBloc)
      ..registerSingleton<GoRouter>(router);
    addTearDown(() async {
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
    await tester.pump();

    expect(
      tester.widget<AdaptiveTheme>(find.byType(AdaptiveTheme)).initial,
      AdaptiveThemeMode.light,
    );
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.system,
    );
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });
}
