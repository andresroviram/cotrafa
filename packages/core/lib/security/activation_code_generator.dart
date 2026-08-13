import 'dart:math';

import 'package:injectable/injectable.dart';

abstract interface class ActivationCodeGenerator {
  String generate();
}

@LazySingleton(as: ActivationCodeGenerator)
final class SecureActivationCodeGenerator implements ActivationCodeGenerator {
  SecureActivationCodeGenerator([@ignoreParam Random? random])
    : _random = random ?? Random.secure();

  final Random _random;

  @override
  String generate() => (_random.nextInt(900000) + 100000).toString();
}
