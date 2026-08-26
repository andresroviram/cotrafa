import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps history and create views atomic and responsive', () {
    final contracts = <({String view, String mobile, String web, String bloc})>[
      (
        view: 'lib/presentation/transfer/view/transfer_view.dart',
        mobile: 'lib/presentation/transfer/view/transfer_mobile.dart',
        web: 'lib/presentation/transfer/view/transfer_web.dart',
        bloc: 'TransferHistoryBloc',
      ),
      (
        view: 'lib/presentation/transfer_create/view/transfer_create_view.dart',
        mobile:
            'lib/presentation/transfer_create/view/transfer_create_mobile.dart',
        web: 'lib/presentation/transfer_create/view/transfer_create_web.dart',
        bloc: 'TransferBloc',
      ),
    ];

    for (final contract in contracts) {
      final view = File(contract.view).readAsStringSync();
      final mobile = File(contract.mobile).readAsStringSync();
      final web = File(contract.web).readAsStringSync();

      expect(view, contains('BlocListener<${contract.bloc},'));
      expect(view, contains('AppNotification'));
      expect(view, contains('ResponsiveBreakpoints.of(context)'));
      expect(view, isNot(contains('BlocBuilder<${contract.bloc},')));
      expect(view, isNot(contains('ScaffoldMessenger')));

      for (final responsiveView in [mobile, web]) {
        expect(responsiveView, contains('BlocBuilder<${contract.bloc},'));
        expect(responsiveView, contains('state.when('));
        expect(responsiveView, isNot(contains('AppNotification')));
        expect(responsiveView, isNot(contains('ScaffoldMessenger')));
      }
    }
  });

  test('keeps listener side effects outside Transfer views', () {
    final widgets = Directory('lib/presentation')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where((file) => !file.path.endsWith('_view.dart'));

    for (final file in widgets) {
      final source = file.readAsStringSync();
      expect(source, isNot(contains('BlocListener<')), reason: file.path);
      expect(source, isNot(contains('ScaffoldMessenger')), reason: file.path);
    }
  });
}
