import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'keeps Auth feature views atomic and responsive rendering consistent',
    () {
      for (final feature in ['login', 'activation']) {
        final root = 'lib/presentation/$feature';
        final view = File('$root/view/${feature}_view.dart').readAsStringSync();
        final mobile = File(
          '$root/view/${feature}_mobile.dart',
        ).readAsStringSync();
        final web = File('$root/view/${feature}_web.dart').readAsStringSync();

        expect(view, contains('BlocListener<AuthBloc, AuthState>'));
        expect(view, contains('ResponsiveBreakpoints.of(context)'));
        expect(view, contains('AppNotification'));
        expect(view, isNot(contains('BlocBuilder<AuthBloc, AuthState>')));
        expect(view, isNot(contains('ScaffoldMessenger')));

        for (final responsiveView in [mobile, web]) {
          expect(responsiveView, contains('BlocBuilder<AuthBloc, AuthState>'));
          expect(responsiveView, contains('state.when('));
          expect(responsiveView, isNot(contains('AppNotification')));
          expect(responsiveView, isNot(contains('ScaffoldMessenger')));
        }
      }
    },
  );

  test('does not emit ScaffoldMessenger feedback from Auth presentation', () {
    final dartFiles = Directory('lib/presentation')
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
}
