import 'dart:io';

import 'package:image/image.dart' as img;

import '../domain/ocr_document.dart';
import '../domain/ocr_service.dart';

enum PreprocessMode { grayscaleContrast, binarizeHalfSize }

/// EXPERIMENT for the "preprocessing made OCR worse" slide.
/// Writes a processed copy next to the original photo and returns its path.
/// Measure it against the untouched photo before you trust it.
Future<String> preprocessForExperiment(String path, PreprocessMode mode) async {
  final bytes = await File(path).readAsBytes();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return path;

  var out = img.bakeOrientation(decoded);
  switch (mode) {
    case PreprocessMode.grayscaleContrast:
      out = img.grayscale(out);
      out = img.adjustColor(out, contrast: 1.6);
    case PreprocessMode.binarizeHalfSize:
      out = img.grayscale(out);
      for (final p in out) {
        final v = p.r > 128 ? 255 : 0;
        p.r = v;
        p.g = v;
        p.b = v;
      }
      out = img.copyResize(out, width: out.width ~/ 2);
  }

  final outPath = '${path}_${mode.name}.jpg';
  await File(outPath).writeAsBytes(img.encodeJpg(out));
  return outPath;
}

/// Decorator: preprocess the photo, then hand it to another OcrService.
class PreprocessingOcrService implements OcrService {
  PreprocessingOcrService(this._inner, this.mode);

  final OcrService _inner;
  final PreprocessMode mode;

  @override
  Future<OcrDocument> recognize(String imagePath) async =>
      _inner.recognize(await preprocessForExperiment(imagePath, mode));

  /// The wrapped service has its own owner, so there is nothing to release.
  @override
  Future<void> dispose() async {}
}