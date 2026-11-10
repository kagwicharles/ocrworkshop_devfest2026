import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ocr_workshop/features/scan/domain/id_parser.dart';
import 'package:ocr_workshop/features/scan/domain/ocr_document.dart';

// A card laid out like the real one: ID NUMBER beside its value, the other
// labels above their values, plus fields we do not extract (SEX, ...).
final _card = OcrDocument(
  const [
    OcrLine('ID NUMBER', Rect.fromLTRB(10, 10, 130, 30)),
    OcrLine('12345678', Rect.fromLTRB(150, 10, 270, 30)),
    OcrLine('FULL NAMES', Rect.fromLTRB(10, 60, 140, 80)),
    OcrLine('SAMPLE PERSON TESTER', Rect.fromLTRB(10, 82, 300, 102)),
    OcrLine('DATE OF BIRTH', Rect.fromLTRB(10, 130, 150, 150)),
    OcrLine('01.01.1990', Rect.fromLTRB(10, 152, 120, 172)),
    OcrLine('SEX', Rect.fromLTRB(10, 200, 50, 220)),
    OcrLine('MALE', Rect.fromLTRB(10, 222, 80, 242)),
    OcrLine('DISTRICT OF BIRTH', Rect.fromLTRB(150, 200, 330, 220)),
    OcrLine('KIAMBU', Rect.fromLTRB(150, 222, 240, 242)),
  ],
  const Size(600, 400),
);

void main() {
  final fields = const IdParser().parse(_card);

  test('ID number beside its label', () {
    expect(fields.idNumber, '12345678');
  });

  test('FULL NAMES fills the name fields', () {
    expect(fields.surname, 'SAMPLE PERSON TESTER');
    expect(fields.givenNames, 'SAMPLE PERSON TESTER');
  });

  test('date of birth above', () {
    expect(fields.dateOfBirth, '01.01.1990');
  });

  test('district of birth is not confused with the SEX field', () {
    expect(fields.districtOfBirth, 'KIAMBU');
  });
}