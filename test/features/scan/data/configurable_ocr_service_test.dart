import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ocr_workshop/features/scan/data/configurable_ocr_service.dart';
import 'package:ocr_workshop/features/scan/domain/ocr_document.dart';
import 'package:ocr_workshop/features/scan/domain/ocr_service.dart';

class _Fake implements OcrService {
  _Fake(this.doc, {this.fail = false});
  final OcrDocument doc;
  final bool fail;
  int calls = 0;

  @override
  Future<OcrDocument> recognize(String imagePath) async {
    calls++;
    if (fail) throw Exception('server down');
    return doc;
  }

  @override
  Future<void> dispose() async {}
}

OcrDocument _doc(int lines, {String engine = 'on-device'}) => OcrDocument(
  [for (var i = 0; i < lines; i++) OcrLine('L$i', const Rect.fromLTRB(0, 0, 1, 1))],
  const Size(100, 100),
  engine: engine,
);

void main() {
  late _Fake device, pre, server;

  ConfigurableOcrService build({
    required bool preprocess,
    required bool allowServer,
    bool serverFails = false,
    int deviceLines = 2,
  }) {
    device = _Fake(_doc(deviceLines));
    pre = _Fake(_doc(deviceLines));
    server = _Fake(_doc(9, engine: 'server'), fail: serverFails);
    return ConfigurableOcrService(
      onDevice: device,
      preprocessed: pre,
      server: server,
      usePreprocess: () => preprocess,
      allowServer: () => allowServer,
    );
  }

  test('uses the preprocessed pipeline only when the toggle is on', () async {
    await build(preprocess: true, allowServer: false, deviceLines: 8)
        .recognize('/tmp/a.jpg');
    expect(pre.calls, 1);
    expect(device.calls, 0);
  });

  test('falls back to the server only with consent and too few lines', () async {
    final doc =
    await build(preprocess: false, allowServer: true).recognize('/tmp/a.jpg');
    expect(doc.engine, 'server');
  });

  test('never uploads without consent', () async {
    final doc =
    await build(preprocess: false, allowServer: false).recognize('/tmp/a.jpg');
    expect(doc.engine, 'on-device');
    expect(server.calls, 0);
  });

  test('keeps the on-device result when the phone read enough', () async {
    await build(preprocess: false, allowServer: true, deviceLines: 8)
        .recognize('/tmp/a.jpg');
    expect(server.calls, 0);
  });

  test('a server failure never breaks the scan', () async {
    final doc = await build(preprocess: false, allowServer: true, serverFails: true)
        .recognize('/tmp/a.jpg');
    expect(doc.engine, 'on-device');
  });
}