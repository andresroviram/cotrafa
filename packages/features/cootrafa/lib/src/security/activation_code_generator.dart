import 'dart:math';

abstract interface class ActivationCodeGenerator {
  String generate();
}

final class SecureActivationCodeGenerator implements ActivationCodeGenerator {
  SecureActivationCodeGenerator([Random? random])
    : _random = random ?? Random.secure();

  final Random _random;

  @override
  String generate() => (_random.nextInt(900000) + 100000).toString();
}
