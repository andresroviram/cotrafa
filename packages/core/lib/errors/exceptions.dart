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
