import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ocr_workshop/features/scan/domain/id_parser.dart';
import 'package:ocr_workshop/features/scan/domain/ocr_comparator.dart';
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
    if (fail) throw Exception('boom');
    return doc;
  }

  @override
  Future<void> dispose() async {}
}

const _good = OcrDocument(
  [
    OcrLine('SURNAME', Rect.fromLTRB(10, 10, 110, 30)),
    OcrLine('TESTER', Rect.fromLTRB(10, 32, 100, 52)),
  ],
  Size(400, 300),
);

const _empty = OcrDocument([], Size(400, 300));

void main() {
  test('reports lines and fields per variant, in insertion order', () async {
    final comparator = OcrComparator(
      parser: const IdParser(),
      variants: {'Original': _Fake(_good), 'Binarized': _Fake(_empty)},
    );
    final results = await comparator.compare('/tmp/a.jpg');

    expect(results.map((r) => r.name), ['Original', 'Binarized']);
    expect(results[0].lineCount, 2);
    expect(results[0].fieldsFound, 1);
    expect(results[1].lineCount, 0);
    expect(results[1].fieldsFound, 0);
  });

  test('a failing variant is reported, not thrown', () async {
    final comparator = OcrComparator(
      parser: const IdParser(),
      variants: {'Original': _Fake(_good), 'Server': _Fake(_good, fail: true)},
    );
    final results = await comparator.compare('/tmp/a.jpg');
    expect(results[1].failed, isTrue);
    expect(results[0].failed, isFalse);
  });

  test('warms up the first variant once before timing', () async {
    final first = _Fake(_good);
    final comparator =
    OcrComparator(parser: const IdParser(), variants: {'Original': first});
    await comparator.compare('/tmp/a.jpg');
    expect(first.calls, 2); // 1 warm-up + 1 timed
  });
}