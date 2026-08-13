import 'package:flutter/material.dart';

class TransferView extends StatelessWidget {
  const TransferView({super.key});

  static const String path = '/transfer';
  static const String name = 'transfer';

  static Widget create() => const TransferView();

  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Transferencias'));
}
