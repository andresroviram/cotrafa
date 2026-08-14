import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps TransferView atomic and responsive rendering consistent', () {
    final view = File(
      'lib/presentation/transfer/view/transfer_view.dart',
    ).readAsStringSync();
    final mobile = File(
      'lib/presentation/transfer/view/transfer_mobile.dart',
    ).readAsStringSync();
    final web = File(
      'lib/presentation/transfer/view/transfer_web.dart',
    ).readAsStringSync();

    expect(view, contains('BlocListener<TransferBloc, TransferState>'));
    expect(view, contains('AppNotification'));
    expect(view, contains('ResponsiveBreakpoints.of(context)'));
    expect(view, isNot(contains('BlocBuilder<TransferBloc, TransferState>')));
    expect(view, isNot(contains('ScaffoldMessenger')));

    for (final responsiveView in [mobile, web]) {
      expect(
        responsiveView,
        contains('BlocBuilder<TransferBloc, TransferState>'),
      );
      expect(responsiveView, contains('state.resolve('));
      expect(responsiveView, isNot(contains('AppNotification')));
      expect(responsiveView, isNot(contains('ScaffoldMessenger')));
    }
  });

  test('keeps listener side effects outside Transfer widgets', () {
    final widgets = Directory('lib/presentation/transfer/widgets')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in widgets) {
      final source = file.readAsStringSync();
      expect(source, isNot(contains('BlocListener<')), reason: file.path);
      expect(source, isNot(contains('ScaffoldMessenger')), reason: file.path);
    }
  });
}
