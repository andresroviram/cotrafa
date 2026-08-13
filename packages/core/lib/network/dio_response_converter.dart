import 'package:dio/dio.dart';

typedef OnResponseValue<T> = T Function(Map<String, dynamic> json);

extension DioResponseConverter on Response<dynamic> {
  T withConverter<T>({required OnResponseValue<T> callback}) {
    final body = (data ?? <String, dynamic>{}) as Map<String, dynamic>;
    return callback(body);
  }

  List<T> withListConverter<T>({required OnResponseValue<T> callback}) {
    return (data as List<dynamic>)
        .map(
          (dynamic e) =>
              callback((e ?? <String, dynamic>{}) as Map<String, dynamic>),
        )
        .toList();
  }

  T withConverterFromKey<T>(
    String key, {
    required OnResponseValue<T> callback,
  }) {
    final body = data as Map<String, dynamic>;
    return callback((body[key] ?? <String, dynamic>{}) as Map<String, dynamic>);
  }

  List<T> withListConverterFromKey<T>(
    String key, {
    required OnResponseValue<T> callback,
  }) {
    final body = data as Map<String, dynamic>;
    return (body[key] as List<dynamic>)
        .map(
          (dynamic e) =>
              callback((e ?? <String, dynamic>{}) as Map<String, dynamic>),
        )
        .toList();
  }
}
