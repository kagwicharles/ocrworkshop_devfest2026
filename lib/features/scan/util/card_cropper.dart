import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show Rect, Size;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class _CropArgs {
  const _CropArgs(this.path, this.view, this.frame);
  final String path;
  final Size view;
  final Rect frame;
}

Future<String> cropToFrame({
  required String path,
  required Size viewSize,
  required Rect frame,
}) =>
    compute(_crop, _CropArgs(path, viewSize, frame));

String _crop(_CropArgs a) {
  final decoded = img.decodeImage(File(a.path).readAsBytesSync());
  if (decoded == null) return a.path;

  // Apply EXIF rotation so pixels match what the user saw in portrait.
  final image = img.bakeOrientation(decoded);
  final iw = image.width.toDouble();
  final ih = image.height.toDouble();

  // Same math BoxFit.cover uses: scale to fill, then center (overflow is cut).
  final scale = math.max(a.view.width / iw, a.view.height / ih);
  final dx = (iw * scale - a.view.width) / 2;
  final dy = (ih * scale - a.view.height) / 2;

  final x = ((a.frame.left + dx) / scale).round().clamp(0, image.width - 1);
  final y = ((a.frame.top + dy) / scale).round().clamp(0, image.height - 1);
  final w = (a.frame.width / scale).round().clamp(1, image.width - x);
  final h = (a.frame.height / scale).round().clamp(1, image.height - y);

  final cropped = img.copyCrop(image, x: x, y: y, width: w, height: h);
  final outPath = '${a.path}_card.jpg';
  File(outPath).writeAsBytesSync(img.encodeJpg(cropped, quality: 95));
  return outPath;
}