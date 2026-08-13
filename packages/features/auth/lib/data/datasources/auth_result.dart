import 'package:core/errors/error.dart';
import 'package:core/errors/result.dart';

enum AuthError {
  unauthorized,
  clientNotPending,
  identifierTaken,
  invalidCredentials,
  storageFailure,
}

sealed class AuthResult<T> {
  const AuthResult();

  const factory AuthResult.ok(T value) = AuthSuccess<T>;
  const factory AuthResult.failure(AuthError error) = AuthErrorResult<T>;

  T? get value => switch (this) {
    AuthSuccess<T>(value: final value) => value,
    AuthErrorResult<T>() => null,
  };

  AuthError? get error => switch (this) {
    AuthSuccess<T>() => null,
    AuthErrorResult<T>(error: final error) => error,
  };

  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(AuthError error) onFailure,
  }) => switch (this) {
    AuthSuccess<T>(value: final value) => onSuccess(value),
    AuthErrorResult<T>(error: final error) => onFailure(error),
  };
}

final class AuthSuccess<T> extends AuthResult<T> {
  const AuthSuccess(this.value);

  @override
  final T value;
}

final class AuthErrorResult<T> extends AuthResult<T> {
  const AuthErrorResult(this.error);

  @override
  final AuthError error;
}

extension AuthResultConversion<T> on AuthResult<T> {
  Result<T> toDomainResult() => fold(
    onSuccess: Success<T>.new,
    onFailure: (error) => Error<T>(error.toFailure()),
  );
}

extension FutureAuthResultConversion<T> on Future<AuthResult<T>> {
  Future<Result<T>> toDomainResult() async => (await this).toDomainResult();
}

extension AuthErrorConversion on AuthError {
  Failure toFailure() => switch (this) {
    AuthError.unauthorized => const UnauthorizedFailure(),
    AuthError.clientNotPending => const ValidationFailure(
      message: 'Client is not pending activation.',
    ),
    AuthError.identifierTaken => const DuplicateFailure(),
    AuthError.invalidCredentials => const AuthFailure(),
    AuthError.storageFailure => const StorageFailure(),
  };
}
