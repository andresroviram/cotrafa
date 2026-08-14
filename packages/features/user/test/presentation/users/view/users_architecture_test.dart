import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps UsersView atomic and rendering inside responsive views', () {
    final view = File(
      'lib/presentation/users/view/users_view.dart',
    ).readAsStringSync();
    final mobile = File(
      'lib/presentation/users/view/users_mobile.dart',
    ).readAsStringSync();
    final web = File(
      'lib/presentation/users/view/users_web.dart',
    ).readAsStringSync();

    expect(view, contains('BlocListener<UserBloc, UserState>'));
    expect(view, contains('ResponsiveBreakpoints.of(context)'));
    expect(view, isNot(contains('BlocBuilder<UserBloc, UserState>')));
    expect(view, isNot(contains('ScaffoldMessenger')));

    for (final responsiveView in [mobile, web]) {
      expect(responsiveView, contains('BlocBuilder<UserBloc, UserState>'));
      expect(responsiveView, contains('state.resolve('));
      expect(responsiveView, isNot(contains('AppNotification')));
      expect(responsiveView, isNot(contains('ScaffoldMessenger')));
    }
  });
}
