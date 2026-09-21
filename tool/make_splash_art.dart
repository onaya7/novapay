// Renders the splash artwork with the app's own typeface and text engine.
//
// Run through `flutter test` rather than `dart run` because rasterising text
// needs a Flutter engine; `make splash-art` wraps it. Output is white on
// transparent, so the generator composites it over the brand colour instead of
// baking a background in.
//
// Two exports, because the two slots crop differently:
//   wordmark.png           the full lockup. Bundled as an app asset too, so
//                          SplashView hands off from the native screen
//                          without a seam
//   android12/mark.png     the initial alone, for the Android 12+
//                          SplashScreen API, which masks its icon to a
//                          circle. Native-only, so it sits in an
//                          undeclared subdirectory and never ships
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const String _family = 'PlusJakartaSans';
const String _fontPath = 'assets/fonts/PlusJakartaSans-Bold.ttf';
const String _outDir = 'assets/splash';

// flutter_native_splash treats the source as 4x, so these divide by four on
// screen: 220dp for the lockup, which is about 60% of a 360dp phone.
const double _wordmarkWidth = 880;

// Paired with icon_background_color, Android 12 wants a 960px canvas with the
// art inside the inner 640px circle.
const double _markCanvas = 960;
const double _markHeight = 340;
const double _markCircleDiameter = 640;

void main() {
  testWidgets('renders the splash artwork', (tester) async {
    await _loadFont();
    await tester.runAsync(() async {
      final wordmark = _fitToWidth('Novapay', _wordmarkWidth);
      await _write('wordmark.png', await _rasterise(wordmark.size, wordmark));

      final mark = _fitToHeight('N', _markHeight);
      final radius = Offset(mark.width, mark.height).distance / 2;
      if (radius > _markCircleDiameter / 2) {
        throw StateError('mark ${mark.size} escapes the Android 12 circle');
      }
      await _write(
        'android12/mark.png',
        await _rasterise(const Size(_markCanvas, _markCanvas), mark),
      );
    });
  });
}

Future<void> _loadFont() async {
  final bytes = File(_fontPath).readAsBytesSync();
  await (FontLoader(
    _family,
  )..addFont(Future<ByteData>.value(ByteData.sublistView(bytes)))).load();
}

TextPainter _layout(String text, double fontSize) => TextPainter(
  text: TextSpan(
    text: text,
    style: TextStyle(
      fontFamily: _family,
      fontWeight: FontWeight.w700,
      fontSize: fontSize,
      height: 1,
      color: const Color(0xFFFFFFFF),
    ),
  ),
  textDirection: TextDirection.ltr,
)..layout();

TextPainter _fitToWidth(String text, double width) {
  final probe = _layout(text, 100);
  return _layout(text, 100 * width / probe.width);
}

TextPainter _fitToHeight(String text, double height) {
  final probe = _layout(text, 100);
  return _layout(text, 100 * height / probe.height);
}

/// Centres the painter on [size], so the caller controls the canvas and the
/// art never sits flush against an edge the platform may crop.
Future<ui.Image> _rasterise(Size size, TextPainter painter) {
  final recorder = ui.PictureRecorder();
  painter.paint(
    Canvas(recorder),
    Offset(
      (size.width - painter.width) / 2,
      (size.height - painter.height) / 2,
    ),
  );
  return recorder.endRecording().toImage(size.width.ceil(), size.height.ceil());
}

Future<void> _write(String name, ui.Image image) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  File('$_outDir/$name')
    ..createSync(recursive: true)
    ..writeAsBytesSync(data!.buffer.asUint8List());
  stdout.writeln('$_outDir/$name  ${image.width}x${image.height}');
}
