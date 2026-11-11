import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ocr_workshop/features/scan/domain/id_parser.dart';
import 'package:ocr_workshop/features/scan/domain/ocr_document.dart';

OcrDocument _doc(List<OcrLine> lines) => OcrDocument(lines, const Size(600, 400));

void main() {
  test('label and value merged into one line', () {
    final doc = _doc(const [
      OcrLine('ID NUMBER 12345678', Rect.fromLTRB(10, 10, 270, 30)),
    ]);
    expect(const IdParser().parse(doc).idNumber, '12345678');
  });

  test('label with no space before the number', () {
    final doc = _doc(const [
      OcrLine('IDNUMBER12345678', Rect.fromLTRB(10, 10, 270, 30)),
    ]);
    expect(const IdParser().parse(doc).idNumber, '12345678');
  });

  test('a merged row with two labels: serial number then ID number', () {
    final doc = _doc(const [
      OcrLine('SERIAL NUMBER 123456789 ID NUMBER 12345678',
          Rect.fromLTRB(10, 10, 500, 30)),
    ]);
    expect(const IdParser().parse(doc).idNumber, '12345678');
  });

  test('number grouped with spaces', () {
    final doc = _doc(const [
      OcrLine('ID NUMBER: 12 345 678', Rect.fromLTRB(10, 10, 270, 30)),
    ]);
    expect(const IdParser().parse(doc).idNumber, '12 345 678');
  });

  test('label and value as separate lines on the same row', () {
    final doc = _doc(const [
      OcrLine('ID NUMBER', Rect.fromLTRB(10, 10, 130, 30)),
      OcrLine('12345678', Rect.fromLTRB(150, 12, 270, 32)),
    ]);
    expect(const IdParser().parse(doc).idNumber, '12345678');
  });

  test('label unreadable: the single 8-digit line is used', () {
    final doc = _doc(const [
      OcrLine('IO NUM8ER', Rect.fromLTRB(10, 10, 130, 30)), // label too garbled to match
      OcrLine('REPUBLIC OF KENYA', Rect.fromLTRB(10, 60, 300, 80)),
      OcrLine('12345678', Rect.fromLTRB(150, 12, 270, 32)),
    ]);
    expect(const IdParser().parse(doc).idNumber, '12345678');
  });

  test('two candidate numbers and no usable label: refuses to guess', () {
    final doc = _doc(const [
      OcrLine('12345678', Rect.fromLTRB(10, 10, 130, 30)),
      OcrLine('87654321', Rect.fromLTRB(10, 60, 130, 80)),
    ]);
    expect(const IdParser().parse(doc).idNumber, isNull);
  });

  test('merged row: date of birth is cut before the next label', () {
    final doc = _doc(const [
      OcrLine('DATE OF BIRTH 01.01.1990 DISTRICT OF BIRTH KIAMBU',
          Rect.fromLTRB(10, 10, 560, 30)),
    ]);
    final f = const IdParser().parse(doc);
    expect(f.dateOfBirth, '01.01.1990');
    expect(f.districtOfBirth, 'KIAMBU');
  });

  test('merged full names', () {
    final doc = _doc(const [
      OcrLine('FULL NAMES SAMPLE PERSON TESTER', Rect.fromLTRB(10, 10, 400, 30)),
    ]);
    expect(const IdParser().parse(doc).surname, 'SAMPLE PERSON TESTER');
  });

  test('GIVEN NAMES is not read as the shorter GIVEN NAME label', () {
    final doc = _doc(const [
      OcrLine('GIVEN NAMES', Rect.fromLTRB(10, 10, 140, 30)),
      OcrLine('SAMPLE PERSON', Rect.fromLTRB(10, 32, 160, 52)),
    ]);
    expect(const IdParser().parse(doc).givenNames, 'SAMPLE PERSON');
  });

  test('a bilingual label is not taken as the value', () {
    final doc = _doc(const [
      OcrLine('SURNAME / JINA LA UKOO', Rect.fromLTRB(10, 10, 300, 30)),
      OcrLine('TESTER', Rect.fromLTRB(10, 32, 100, 52)),
    ]);
    expect(const IdParser().parse(doc).surname, 'TESTER');
  });
}