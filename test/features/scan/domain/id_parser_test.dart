import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ocr_workshop/features/scan/domain/id_fields.dart';
import 'package:ocr_workshop/features/scan/domain/id_parser.dart';
import 'package:ocr_workshop/features/scan/domain/ocr_document.dart';

OcrDocument _card(String surnameLabel) => OcrDocument(
      [
        OcrLine(surnameLabel, const Rect.fromLTRB(10, 10, 110, 30)),
        const OcrLine('TESTER', Rect.fromLTRB(10, 32, 100, 52)),
        const OcrLine('GIVEN NAMES', Rect.fromLTRB(10, 70, 140, 90)),
        const OcrLine('SAMPLE PERSON', Rect.fromLTRB(10, 92, 180, 112)),
        const OcrLine('DOB: 01 JAN 1990', Rect.fromLTRB(10, 130, 200, 150)),
      ],
      const Size(400, 300),
    );

void main() {
  group('similarity', () {
    test('tolerates OCR noise in labels', () {
      expect(similarity('SURNAM E', 'SURNAME'), 1.0);
      expect(similarity('SURNAMF', 'SURNAME'), greaterThanOrEqualTo(0.8));
      expect(similarity('5URNAME', 'SURNAME'), greaterThanOrEqualTo(0.8));
    });

    test('rejects different words', () {
      expect(similarity('GIVEN NAMES', 'SURNAME'), lessThan(0.5));
    });
  });

  group('IdParser', () {
    for (final label in ['SURNAME', 'SURNAM E', '5URNAME', 'SURNAMF']) {
      test('finds the value below the label "$label"', () {
        final fields = const IdParser().parse(_card(label));
        expect(fields.surname, 'TESTER');
        expect(fields.givenNames, 'SAMPLE PERSON');
      });
    }

    test('reads a value after a colon on the same line', () {
      final fields = const IdParser().parse(_card('SURNAME'));
      expect(fields.dateOfBirth, '01 JAN 1990');
    });

    test('returns null for fields that are not on the card', () {
      final fields = const IdParser().parse(_card('SURNAME'));
      expect(fields.idNumber, isNull);
      expect(fields, isNot(const IdFields()));
    });
  });
}
