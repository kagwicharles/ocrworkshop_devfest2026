import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ocr_workshop/features/scan/domain/id_parser.dart';
import 'package:ocr_workshop/features/scan/domain/ocr_document.dart';

OcrDocument _doc(List<OcrLine> lines) => OcrDocument(lines, const Size(400, 300));

void main() {
  test('value to the right of the label on the same row', () {
    final doc = _doc(const [
      OcrLine('SURNAME', Rect.fromLTRB(10, 10, 110, 30)),
      OcrLine('TESTER', Rect.fromLTRB(130, 10, 230, 30)),
    ]);
    expect(const IdParser().parse(doc).surname, 'TESTER');
  });

  test('bilingual label', () {
    final doc = _doc(const [
      OcrLine('DATE OF BIRTH / TAREHE YA KUZALIWA', Rect.fromLTRB(10, 10, 300, 30)),
      OcrLine('01.01.1990', Rect.fromLTRB(10, 32, 100, 50)),
    ]);
    expect(const IdParser().parse(doc).dateOfBirth, '01.01.1990');
  });

  test('label and value on one line, no colon', () {
    final doc = _doc(const [
      OcrLine('SURNAME TESTER', Rect.fromLTRB(10, 10, 200, 30)),
    ]);
    expect(const IdParser().parse(doc).surname, 'TESTER');
  });

  test('ignores a line that is far below the label', () {
    final doc = _doc(const [
      OcrLine('SURNAME', Rect.fromLTRB(10, 10, 110, 30)),
      OcrLine('TESTER', Rect.fromLTRB(10, 300, 100, 320)),
    ]);
    expect(const IdParser().parse(doc).surname, isNull);
  });

  test('does not take the next label as a value', () {
    final doc = _doc(const [
      OcrLine('SURNAME', Rect.fromLTRB(10, 10, 110, 30)),
      OcrLine('GIVEN NAMES', Rect.fromLTRB(10, 32, 140, 50)),
    ]);
    expect(const IdParser().parse(doc).surname, isNull);
  });
}