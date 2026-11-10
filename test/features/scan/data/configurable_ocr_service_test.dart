import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ocr_workshop/features/scan/data/configurable_ocr_service.dart';
import 'package:ocr_workshop/features/scan/domain/ocr_document.dart';
import 'package:ocr_workshop/features/scan/domain/ocr_service.dart';

class _Fake implements OcrService {
  int calls = 0;

  @override
  Future<OcrDocument> recognize(String imagePath) async {
    calls++;
    return const OcrDocument([], Size(100, 100));
  }

  @override
  Future<void> dispose() async {}
}

void main() {
  test('runs the plain on-device pipeline by default', () async {
    final plain = _Fake(), pre = _Fake();
    final service = ConfigurableOcrService(
      onDevice: plain,
      preprocessed: pre,
      usePreprocess: () => false,
    );
    await service.recognize('/tmp/a.jpg');
    expect(plain.calls, 1);
    expect(pre.calls, 0);
  });

  test('switches to the preprocessed pipeline when the toggle is on', () async {
    final plain = _Fake(), pre = _Fake();
    final service = ConfigurableOcrService(
      onDevice: plain,
      preprocessed: pre,
      usePreprocess: () => true,
    );
    await service.recognize('/tmp/a.jpg');
    expect(pre.calls, 1);
    expect(plain.calls, 0);
  });
}