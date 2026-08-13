import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

class CredentialHasher {
  CredentialHasher({
    this.memoryKiB = 19456,
    this.iterations = 2,
    this.parallelism = 1,
    this.hashLength = 32,
    List<int> Function()? saltFactory,
  }) : _saltFactory = saltFactory ?? _secureSalt;

  final int memoryKiB;
  final int iterations;
  final int parallelism;
  final int hashLength;
  final List<int> Function() _saltFactory;

  Future<String> hash(String secret) async {
    final List<int> salt = _saltFactory();
    final List<int> bytes = await _derive(secret, salt);
    return '\$argon2id\$v=19\$m=$memoryKiB,t=$iterations,p=$parallelism\$'
        '${base64UrlEncode(salt)}\$${base64UrlEncode(bytes)}';
  }

  Future<bool> verify(String secret, String encoded) async {
    final List<String> parts = encoded.split(r'$');
    if (parts.length != 6 || parts[1] != 'argon2id' || parts[2] != 'v=19') {
      return false;
    }
    final Map<String, int> parameters = <String, int>{
      for (final String item in parts[3].split(','))
        item.split('=').first: int.parse(item.split('=').last),
    };
    final CredentialHasher verifier = CredentialHasher(
      memoryKiB: parameters['m']!,
      iterations: parameters['t']!,
      parallelism: parameters['p']!,
      hashLength: base64Url.decode(parts[5]).length,
      saltFactory: () => base64Url.decode(parts[4]),
    );
    final List<int> actual = await verifier._derive(
      secret,
      base64Url.decode(parts[4]),
    );
    final List<int> expected = base64Url.decode(parts[5]);
    int difference = actual.length ^ expected.length;
    for (
      int index = 0;
      index < actual.length && index < expected.length;
      index++
    ) {
      difference |= actual[index] ^ expected[index];
    }
    return difference == 0;
  }

  Future<List<int>> _derive(String secret, List<int> salt) async {
    final SecretKey key = await Argon2id(
      parallelism: parallelism,
      memory: memoryKiB,
      iterations: iterations,
      hashLength: hashLength,
    ).deriveKey(secretKey: SecretKey(utf8.encode(secret)), nonce: salt);
    return key.extractBytes();
  }

  static List<int> _secureSalt() {
    final Random random = Random.secure();
    return List<int>.generate(16, (_) => random.nextInt(256));
  }
}
