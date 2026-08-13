import 'package:core/errors/error.dart';
import 'package:core/errors/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Future values become Success through Result', () async {
    expect(await Future<int>.value(7).toResult(), const Success<int>(7));
  });

  test('Result maps Core exceptions to their matching Failure', () async {
    final cases = <Object, Type>{
      const AuthException(): AuthFailure,
      const UnauthorizedException(): UnauthorizedFailure,
      const ValidationException(message: 'Not pending'): ValidationFailure,
      const DuplicateException(): DuplicateFailure,
      const StorageException(): StorageFailure,
      const NetworkException(): NetworkFailure,
      const ServerException(): ServerFailure,
    };

    for (final entry in cases.entries) {
      final result = await Future<void>.error(entry.key).toResult();

      expect(result.errorOrNull.runtimeType, entry.value);
    }
  });

  test(
    'Result accepts a boundary-specific fallback for unknown errors',
    () async {
      final result = await Future<void>.error(
        Exception('drift failure'),
      ).toResult(fallback: const StorageFailure());

      expect(result, const Error<void>(StorageFailure()));
    },
  );
}
