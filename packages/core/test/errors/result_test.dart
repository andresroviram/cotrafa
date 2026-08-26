import 'package:core/errors/error.dart';
import 'package:core/errors/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Future values become Success through Result', () async {
    expect(await Future<int>.value(7).toResult(), const Success<int>(7));
  });

  test('Result maps Core exceptions and preserves their messages', () async {
    final cases = <Object, (Type, String)>{
      const AuthException(message: 'Invalid credentials'): (
        AuthFailure,
        'Invalid credentials',
      ),
      const UnauthorizedException(message: 'Admin only'): (
        UnauthorizedFailure,
        'Admin only',
      ),
      const ValidationException(message: 'Not pending'): (
        ValidationFailure,
        'Not pending',
      ),
      const DuplicateException(message: 'Email already exists'): (
        DuplicateFailure,
        'Email already exists',
      ),
      const NotFoundException(message: 'User not found'): (
        NotFoundFailure,
        'User not found',
      ),
      const StorageException(message: 'Write failed'): (
        StorageFailure,
        'Write failed',
      ),
      const NetworkException(message: 'Offline'): (NetworkFailure, 'Offline'),
      const ServerException(message: 'Unavailable'): (
        ServerFailure,
        'Unavailable',
      ),
    };

    for (final entry in cases.entries) {
      final result = await Future<void>.error(entry.key).toResult();

      expect(result.errorOrNull.runtimeType, entry.value.$1);
      expect(result.errorOrNull?.message, entry.value.$2);
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
