import 'package:core/network/dio_response_converter.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DioResponseConverter', () {
    test('converts a response body into one model', () {
      final response = _response(<String, dynamic>{'id': 1, 'name': 'One'});

      expect(
        response.withConverter(callback: _Item.fromJson),
        const _Item(1, 'One'),
      );
    });

    test('converts a response body into a model list', () {
      final response = _response(<Map<String, dynamic>>[
        <String, dynamic>{'id': 1, 'name': 'One'},
        <String, dynamic>{'id': 2, 'name': 'Two'},
      ]);

      expect(
        response.withListConverter(callback: _Item.fromJson),
        const <_Item>[_Item(1, 'One'), _Item(2, 'Two')],
      );
    });

    test('converts one keyed response value into a model', () {
      final response = _response(<String, dynamic>{
        'item': <String, dynamic>{'id': 1, 'name': 'One'},
      });

      expect(
        response.withConverterFromKey('item', callback: _Item.fromJson),
        const _Item(1, 'One'),
      );
    });

    test('converts a keyed response value into a model list', () {
      final response = _response(<String, dynamic>{
        'items': <Map<String, dynamic>>[
          <String, dynamic>{'id': 1, 'name': 'One'},
          <String, dynamic>{'id': 2, 'name': 'Two'},
        ],
      });

      expect(
        response.withListConverterFromKey('items', callback: _Item.fromJson),
        const <_Item>[_Item(1, 'One'), _Item(2, 'Two')],
      );
    });
  });
}

Response<dynamic> _response(Object data) => Response<dynamic>(
  requestOptions: RequestOptions(path: '/items'),
  data: data,
);

final class _Item {
  const _Item(this.id, this.name);

  factory _Item.fromJson(Map<String, dynamic> json) =>
      _Item(json['id']! as int, json['name']! as String);

  final int id;
  final String name;

  @override
  bool operator ==(Object other) =>
      other is _Item && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);
}
