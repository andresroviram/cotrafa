import 'dart:io';

import 'package:core/errors/error.dart';
import 'package:core/errors/result.dart';
import 'package:feature_auth/data/datasources/auth_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sealed AuthResult converts success without casts', () async {
    const source = AuthResult<int>.ok(7);

    expect(source, isA<AuthSuccess<int>>());
    expect(
      source.fold(
        onSuccess: (value) => 'value:$value',
        onFailure: (error) => 'error:$error',
      ),
      'value:7',
    );
    expect(await Future.value(source).toDomainResult(), const Success<int>(7));
  });

  test('sealed AuthResult converts every AuthError to a Failure', () async {
    final cases = <AuthError, Type>{
      AuthError.unauthorized: UnauthorizedFailure,
      AuthError.clientNotPending: ValidationFailure,
      AuthError.identifierTaken: DuplicateFailure,
      AuthError.invalidCredentials: AuthFailure,
      AuthError.storageFailure: StorageFailure,
    };

    for (final entry in cases.entries) {
      final source = AuthResult<int>.failure(entry.key);
      final result = await Future.value(source).toDomainResult();

      expect(source, isA<AuthErrorResult<int>>());
      expect(
        source.fold(onSuccess: (value) => null, onFailure: (error) => error),
        entry.key,
      );
      expect(result.errorOrNull.runtimeType, entry.value);
    }
  });

  test('Core remains free of Cootrafa Auth result policy', () {
    final coreErrors = _coreErrorsRoot();
    final sources = coreErrors
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .map((file) => file.readAsStringSync())
        .join('\n');

    expect(Directory('${coreErrors.path}/auth').existsSync(), isFalse);
    expect(sources, isNot(contains('enum AuthError')));
    expect(sources, isNot(contains('sealed class AuthResult')));
  });
}

Directory _coreErrorsRoot() => <Directory>[
  Directory('../../core/lib/errors'),
  Directory('${Directory.current.path}/packages/core/lib/errors'),
].firstWhere((directory) => directory.existsSync());
