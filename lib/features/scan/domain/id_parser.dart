import 'dart:math' as math;
import 'dart:ui';

import 'id_fields.dart';
import 'ocr_document.dart';

/// Classic edit distance (insert, delete, substitute).
int levenshtein(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;
  var prev = List<int>.generate(b.length + 1, (j) => j);
  for (var i = 1; i <= a.length; i++) {
    final curr = List<int>.filled(b.length + 1, 0);
    curr[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      curr[j] = math.min(
        math.min(curr[j - 1] + 1, prev[j] + 1),
        prev[j - 1] + cost,
      );
    }
    prev = curr;
  }
  return prev[b.length];
}

String _normalize(String s) =>
    s.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

/// 1.0 = identical after normalizing, 0.0 = nothing in common.
double similarity(String a, String b) {
  final x = _normalize(a);
  final y = _normalize(b);
  final longest = math.max(x.length, y.length);
  return longest == 0 ? 1 : 1 - levenshtein(x, y) / longest;
}

// Label synonyms per field. Add the labels YOUR card uses here.
const surnameLabels = ['FULL NAMES', 'LAST NAME', 'FAMILY NAME'];
const givenNameLabels = ['FULL NAMES', 'GIVEN NAME', 'FIRST NAME', 'OTHER NAMES'];
const idNumberLabels = [
  'ID NUMBER:',
  'ID NO',
  'IDENTITY NUMBER',
  'DOCUMENT NUMBER',
  'NATIONAL ID',
];
const dateOfBirthLabels = ['DATE OF BIRTH', 'DOB', 'BIRTH DATE'];

const _allLabels = [
  ...surnameLabels,
  ...givenNameLabels,
  ...idNumberLabels,
  ...dateOfBirthLabels,
];

bool _looksLikeLabel(String text) =>
    _allLabels.any((l) => similarity(text, l) >= 0.8);

/// Bilingual labels such as "DATE OF BIRTH / TAREHE YA KUZALIWA":
/// try each part on its own.
Iterable<String> _headParts(String head) => head
    .split(RegExp(r'[/|]'))
    .map((p) => p.trim())
    .where((p) => p.isNotEmpty);

double _verticalOverlap(Rect a, Rect b) {
  final overlap = math.min(a.bottom, b.bottom) - math.max(a.top, b.top);
  final smaller = math.min(a.height, b.height);
  return smaller <= 0 ? 0 : overlap / smaller;
}

/// Finds the line that looks like one of [labels], then returns its value:
///  1. text after a colon, or after the label on the same line;
///  2. the nearest line just below (not another label);
///  3. the nearest line to the right on the same row (not another label).
String? valueFor(
    OcrDocument doc,
    List<String> labels, {
      double threshold = 0.8,
    }) {
  for (final line in doc.lines) {
    // "SURNAME TESTER" on one line, no colon.
    final upper = line.text.toUpperCase();
    for (final l in labels) {
      if (upper.startsWith('$l ')) {
        final rest = line.text.substring(l.length).trim();
        if (rest.isNotEmpty) return rest;
      }
    }

    final colon = line.text.indexOf(':');
    final head = colon == -1 ? line.text : line.text.substring(0, colon);
    final matches = _headParts(head)
        .any((part) => labels.any((l) => similarity(part, l) >= threshold));
    if (!matches) continue;

    if (colon != -1) {
      final inline = line.text.substring(colon + 1).trim();
      if (inline.isNotEmpty) return inline;
    }

    final maxGap = line.box.height * 3;
    final below = doc.lines
        .where((o) =>
    !identical(o, line) &&
        o.box.top >= line.box.bottom - 4 &&
        o.box.top - line.box.bottom <= maxGap &&
        o.box.left < line.box.right &&
        o.box.right > line.box.left &&
        !_looksLikeLabel(o.text))
        .toList()
      ..sort((a, b) => a.box.top.compareTo(b.box.top));
    if (below.isNotEmpty) return below.first.text.trim();

    final right = doc.lines
        .where((o) =>
    !identical(o, line) &&
        o.box.left >= line.box.right - 4 &&
        _verticalOverlap(o.box, line.box) > 0.5 &&
        !_looksLikeLabel(o.text))
        .toList()
      ..sort((a, b) => a.box.left.compareTo(b.box.left));
    if (right.isNotEmpty) return right.first.text.trim();
  }
  return null;
}

class IdParser {
  const IdParser();

  IdFields parse(OcrDocument doc) => IdFields(
    surname: valueFor(doc, surnameLabels),
    givenNames: valueFor(doc, givenNameLabels),
    idNumber: valueFor(doc, idNumberLabels),
    dateOfBirth: valueFor(doc, dateOfBirthLabels),
  );
}