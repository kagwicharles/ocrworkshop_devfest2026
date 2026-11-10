import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import '../domain/ocr_document.dart';
import '../domain/ocr_service.dart';

/// Server-side OCR. POSTs the JPEG bytes and expects:
/// {"width": 1000, "height": 700,
///  "lines": [{"text": "...", "left": 0, "top": 0, "right": 10, "bottom": 10}]}
/// See tools/ocr_server.py for a reference server.
class HttpOcrService implements OcrService {
  HttpOcrService(this.endpoint, {this.timeout = const Duration(seconds: 10)});

  final Uri endpoint;
  final Duration timeout;

  @override
  Future<OcrDocument> recognize(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      final request = await client.postUrl(endpoint);
      request.headers.contentType = ContentType('image', 'jpeg');
      request.add(bytes);
      final response = await request.close().timeout(timeout);
      if (response.statusCode != 200) {
        throw HttpException('OCR server returned ${response.statusCode}');
      }
      final body = await response.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;
      final lines = [
        for (final l in json['lines'] as List<dynamic>)
          OcrLine(
            (l as Map<String, dynamic>)['text'] as String,
            Rect.fromLTRB(
              (l['left'] as num).toDouble(),
              (l['top'] as num).toDouble(),
              (l['right'] as num).toDouble(),
              (l['bottom'] as num).toDouble(),
            ),
          ),
      ];
      return OcrDocument(
        lines,
        Size(
          (json['width'] as num).toDouble(),
          (json['height'] as num).toDouble(),
        ),
        engine: 'server',
      );
    } finally {
      client.close(force: true);
    }
  }

  @override
  Future<void> dispose() async {}
}