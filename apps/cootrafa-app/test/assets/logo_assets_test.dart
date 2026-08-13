import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'uses the official Cotrafa header logo with a white dark variant',
    () async {
      final light = await _readPng('assets/img/logo.png');
      final dark = await _readPng('assets/img/logo_dark.png');

      expect((light.width, light.height), (199, 68));
      expect((dark.width, dark.height), (199, 68));
      expect(light.alpha, dark.alpha);
      expect(
        light.visibleColors,
        contains(const (red: 15, green: 59, blue: 128)),
      );
      expect(
        dark.visibleColors,
        everyElement(const (red: 255, green: 255, blue: 255)),
      );
    },
  );
}

Future<_PngData> _readPng(String path) async {
  final bytes = await File(path).readAsBytes();
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  final image = frame.image;
  final width = image.width;
  final height = image.height;
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final rgba = data!.buffer.asUint8List();
  final alpha = <int>[];
  final visibleColors = <({int red, int green, int blue})>{};

  for (var index = 0; index < rgba.length; index += 4) {
    final pixelAlpha = rgba[index + 3];
    alpha.add(pixelAlpha);
    if (pixelAlpha == 0) continue;
    visibleColors.add((
      red: _unpremultiply(rgba[index], pixelAlpha),
      green: _unpremultiply(rgba[index + 1], pixelAlpha),
      blue: _unpremultiply(rgba[index + 2], pixelAlpha),
    ));
  }

  image.dispose();
  codec.dispose();
  return _PngData(
    width: width,
    height: height,
    alpha: alpha,
    visibleColors: visibleColors,
  );
}

int _unpremultiply(int channel, int alpha) =>
    (channel * 255 / alpha).round().clamp(0, 255);

final class _PngData {
  const _PngData({
    required this.width,
    required this.height,
    required this.alpha,
    required this.visibleColors,
  });

  final int width;
  final int height;
  final List<int> alpha;
  final Set<({int red, int green, int blue})> visibleColors;
}
