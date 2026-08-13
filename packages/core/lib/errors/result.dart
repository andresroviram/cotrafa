import 'package:core/errors/error.dart';

sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Success<T> && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Success(value: $value)';
}

class Error<T> extends Result<T> {
  final Failure error;
  const Error(this.error);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Error<T> && error == other.error;

  @override
  int get hashCode => error.hashCode;

  @override
  String toString() => 'Error(error: $error)';
}

extension ResultExtensions<T> on Result<T> {
  Result<R> map<R>(R Function(T value) transform) {
    return switch (this) {
      Success(value: final v) => Success(transform(v)),
      Error(error: final e) => Error(e),
    };
  }

  Result<R> flatMap<R>(Result<R> Function(T value) transform) {
    return switch (this) {
      Success(value: final v) => transform(v),
      Error(error: final e) => Error(e),
    };
  }

  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(Failure error) onFailure,
  }) {
    return switch (this) {
      Success(value: final v) => onSuccess(v),
      Error(error: final e) => onFailure(e),
    };
  }

  bool get isSuccess => this is Success<T>;

  bool get isFailure => this is Error<T>;

  T? get valueOrNull => switch (this) {
    Success(value: final v) => v,
    _ => null,
  };

  Failure? get errorOrNull => switch (this) {
    Error(error: final e) => e,
    _ => null,
  };
}

extension FutureResultExtensions<T> on Future<T> {
  Future<Result<T>> toResult({
    Failure fallback = const UnknownFailure(),
  }) async {
    try {
      return Success<T>(await this);
    } on Object catch (error) {
      return Error<T>(_failureFrom(error, fallback));
    }
  }
}

Failure _failureFrom(Object error, Failure fallback) => switch (error) {
  Failure() => error,
  AuthException() => const AuthFailure(),
  UnauthorizedException() => const UnauthorizedFailure(),
  ValidationException(message: final message) => ValidationFailure(
    message: message,
  ),
  DuplicateException() => const DuplicateFailure(),
  StorageException() => const StorageFailure(),
  NetworkException() => const NetworkFailure(),
  ServerException() => const ServerFailure(),
  _ => fallback,
};
