import 'dart:io';
import 'dart:ui' show Size;

import 'package:flutter/painting.dart' show decodeImageFromList;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../domain/ocr_document.dart';
import '../domain/ocr_service.dart';

/// On-device OCR. The Latin model runs locally: no network needed.
class MlKitOcrService implements OcrService {
  MlKitOcrService({TextRecognizer? recognizer})
      : _recognizer =
      recognizer ?? TextRecognizer(script: TextRecognitionScript.latin);

  final TextRecognizer _recognizer;

  @override
  Future<OcrDocument> recognize(String imagePath) async {
    final recognized =
    await _recognizer.processImage(InputImage.fromFilePath(imagePath));

    // ML Kit boxes are in this image's pixel space, so remember its size.
    final bytes = await File(imagePath).readAsBytes();
    final image = await decodeImageFromList(bytes);
    final size = Size(image.width.toDouble(), image.height.toDouble());
    image.dispose();

    final lines = [
      for (final block in recognized.blocks)
        for (final line in block.lines) OcrLine(line.text, line.boundingBox),
    ];
    return OcrDocument(lines, size);
  }

  @override
  Future<void> dispose() => _recognizer.close();
}