import 'package:feature_transfer/presentation/transfer/view/transfer_view.dart';
import 'package:feature_transfer/routes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  test('owns the transfer shell branch', () {
    final route = transferRoutes.routes.single as GoRoute;

    expect(route.path, TransferView.path);
    expect(route.name, TransferView.name);
  });
}
