import 'dart:io';

import 'package:core/env/i_env_config.dart';
import 'package:core/errors/error.dart';
import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_http_formatter/dio_http_formatter.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class DioClient {
  late final Dio _dio;

  DioClient(IEnvConfig env) {
    _dio = Dio(
      BaseOptions(
        baseUrl: env.baseUrl.endsWith('/') ? env.baseUrl : '${env.baseUrl}/',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
          HttpHeaders.acceptHeader: 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      DioCacheInterceptor(
        options: CacheOptions(
          store: MemCacheStore(),
          hitCacheOnNetworkFailure: true,
          maxStale: const Duration(days: 1),
        ),
      ),
      HttpFormatter(),
    ]);
  }

  Dio get dio => _dio;

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response<dynamic>> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response<dynamic>> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response<dynamic>> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Failure _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutFailure();
      case DioExceptionType.badResponse:
        switch (e.response?.statusCode) {
          case 400:
            return BadRequestFailure(
              message: _extractMessage(e.response?.data, 'Solicitud inválida.'),
            );
          case 401:
            return AuthFailure(
              message: _extractMessage(e.response?.data, 'No autorizado.'),
            );
          case 403:
            return UnauthorizedFailure(
              message: _extractMessage(e.response?.data, 'Acceso denegado.'),
            );
          case 404:
            return NotFoundFailure(
              message: _extractMessage(
                e.response?.data,
                'Recurso no encontrado.',
              ),
            );
          case 409:
            return DuplicateFailure(
              message: _extractMessage(
                e.response?.data,
                'El recurso ya existe.',
              ),
            );
          case 500:
          case 501:
          case 502:
          case 503:
            return ServerFailure(
              message: _extractMessage(e.response?.data, 'Error del servidor.'),
              statusCode: e.response?.statusCode,
            );
          default:
            return ServerFailure(
              message: _extractMessage(e.response?.data, 'Error inesperado.'),
              statusCode: e.response?.statusCode,
            );
        }
      case DioExceptionType.cancel:
        return const CacheFailure(message: 'Petición cancelada.');
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        if (e.error.toString().contains('SocketException') ||
            e.error.toString().contains('NetworkException')) {
          return const NetworkFailure();
        }
        return UnknownFailure(message: e.message ?? 'Error desconocido.');
      default:
        return UnknownFailure(message: e.message ?? 'Error desconocido.');
    }
  }

  String _extractMessage(dynamic data, String fallback) {
    if (data is Map<String, dynamic>) {
      return data['message'] as String? ?? fallback;
    }
    return fallback;
  }

  void setToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void removeToken() {
    _dio.options.headers.remove('Authorization');
  }
}
