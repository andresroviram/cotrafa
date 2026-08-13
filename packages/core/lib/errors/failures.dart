part of 'error.dart';

abstract class Failure extends Equatable {
  final String message;
  final int? statusCode;

  const Failure({required this.message, this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];

  @override
  String toString() =>
      '$runtimeType(message: $message, statusCode: $statusCode)';
}

class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'Error de conexión. Verifica tu internet.',
    super.statusCode,
  });
}

class ServerFailure extends Failure {
  const ServerFailure({
    super.message = 'Error del servidor. Intenta más tarde.',
    super.statusCode = 500,
  });
}

class TimeoutFailure extends Failure {
  const TimeoutFailure({
    super.message = 'La solicitud tardó demasiado. Intenta de nuevo.',
    super.statusCode = 408,
  });
}

class CacheFailure extends Failure {
  const CacheFailure({
    super.message = 'Error al acceder a los datos locales.',
    super.statusCode,
  });
}

class ValidationFailure extends Failure {
  final Map<String, String>? errors;

  const ValidationFailure({
    super.message = 'Los datos ingresados no son válidos.',
    this.errors,
    super.statusCode,
  });

  @override
  List<Object?> get props => [message, statusCode, errors];
}

class NotFoundFailure extends Failure {
  const NotFoundFailure({
    super.message = 'No se encontró el recurso solicitado.',
    super.statusCode = 404,
  });
}

class AuthFailure extends Failure {
  const AuthFailure({
    super.message = 'Error de autenticación.',
    super.statusCode = 401,
  });
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({
    super.message = 'No tienes permiso para realizar esta acción.',
    super.statusCode = 403,
  });
}

class InputFailure extends Failure {
  const InputFailure({super.message = 'Entrada inválida.', super.statusCode});
}

class BadRequestFailure extends Failure {
  const BadRequestFailure({
    super.message = 'La solicitud enviada no es válida.',
    super.statusCode = 400,
  });
}

class DuplicateFailure extends Failure {
  const DuplicateFailure({
    super.message = 'El recurso ya existe.',
    super.statusCode = 409,
  });
}

class StorageFailure extends Failure {
  const StorageFailure({
    super.message = 'Error al guardar los datos.',
    super.statusCode,
  });
}

class StorageReadFailure extends Failure {
  const StorageReadFailure({
    super.message = 'Error al leer los datos almacenados.',
    super.statusCode,
  });
}

class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message = 'Ocurrió un error inesperado.',
    super.statusCode,
  });
}
