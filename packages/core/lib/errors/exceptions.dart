part of 'error.dart';

class ServerException implements Exception {
  const ServerException({this.message = 'Server error occurred'});
  final String message;

  @override
  String toString() => 'ServerException: $message';
}

class NetworkException implements Exception {
  const NetworkException({this.message = 'No internet connection'});
  final String message;

  @override
  String toString() => 'NetworkException: $message';
}

class StorageException implements Exception {
  const StorageException({this.message = 'Storage error occurred'});
  final String message;

  @override
  String toString() => 'StorageException: $message';
}

class AuthException implements Exception {
  const AuthException({this.message = 'Authentication failed'});
  final String message;

  @override
  String toString() => 'AuthException: $message';
}

class UnauthorizedException implements Exception {
  const UnauthorizedException({this.message = 'Unauthorized operation'});
  final String message;

  @override
  String toString() => 'UnauthorizedException: $message';
}

class ValidationException implements Exception {
  const ValidationException({required this.message});
  final String message;

  @override
  String toString() => 'ValidationException: $message';
}

class DuplicateException implements Exception {
  const DuplicateException({this.message = 'Resource already exists'});
  final String message;

  @override
  String toString() => 'DuplicateException: $message';
}

class NotFoundException implements Exception {
  const NotFoundException({this.message = 'Resource not found'});
  final String message;

  @override
  String toString() => 'NotFoundException: $message';
}
