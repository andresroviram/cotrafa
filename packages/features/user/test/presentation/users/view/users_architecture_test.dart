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

  test('keeps detail and edit views on the same presentation contract', () {
    for (final feature in ['user_detail', 'user_edit']) {
      final view = File(
        'lib/presentation/users/view/${feature}_view.dart',
      ).readAsStringSync();
      final mobile = File(
        'lib/presentation/users/view/${feature}_mobile.dart',
      ).readAsStringSync();
      final web = File(
        'lib/presentation/users/view/${feature}_web.dart',
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
    }
  });

  test('does not emit ScaffoldMessenger feedback from User presentation', () {
    final dartFiles = Directory('lib/presentation/users')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in dartFiles) {
      expect(
        file.readAsStringSync(),
        isNot(contains('ScaffoldMessenger')),
        reason: file.path,
      );
    }
  });

  test('keeps BlocListener side effects in atomic feature views', () {
    final dartFiles = Directory('lib/presentation/users')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where((file) => !file.path.endsWith('_view.dart'));

    for (final file in dartFiles) {
      expect(
        file.readAsStringSync(),
        isNot(contains('BlocListener<')),
        reason: file.path,
      );
    }
  });
}
