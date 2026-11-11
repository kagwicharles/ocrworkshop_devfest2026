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
const surnameLabels = ['FULL NAMES', 'SURNAME', 'LAST NAME', 'FAMILY NAME'];
const givenNameLabels = [
  'FULL NAMES',
  'GIVEN NAMES',
  'GIVEN NAME',
  'FIRST NAME',
  'OTHER NAMES',
];
const idNumberLabels = [
  'ID NUMBER:',
  'ID NO',
  'IDENTITY NUMBER',
  'DOCUMENT NUMBER',
  'NATIONAL ID',
  'DNUMBER'
];
const dateOfBirthLabels = ['DATE OF BIRTH', 'DOB', 'BIRTH DATE'];
const districtOfBirthLabels = ['DISTRICT OF BIRTH', 'BIRTH DISTRICT'];

final idNumberPattern = RegExp(r'^\d{7,8}$');

const _otherCardLabels = [
  'SEX',
  'SERIAL NUMBER',
  'PLACE OF ISSUE',
  'DATE OF ISSUE',
  'HOLDER SIGN',
];

const _allLabels = [
  ...surnameLabels,
  ...givenNameLabels,
  ...idNumberLabels,
  ...dateOfBirthLabels,
  ...districtOfBirthLabels,
  ..._otherCardLabels,
];

bool _looksLikeLabel(String text) =>
    _allLabels.any((l) => similarity(text, l) >= 0.8);

final _regexCache = <String, RegExp>{};
RegExp _labelRegex(String label) => _regexCache.putIfAbsent(label, () {
  final words = label.trim().split(RegExp(r'\s+')).map(RegExp.escape);
  return RegExp(
    '(?<![A-Za-z0-9])${words.join(r'\s*')}(?![A-Za-z])',
    caseSensitive: false,
  );
});

String _cutAtNextLabel(String rest) {
  var cut = rest.length;
  for (final l in _allLabels) {
    final m = _labelRegex(l).firstMatch(rest);
    if (m != null && m.start < cut) cut = m.start;
  }
  return rest.substring(0, cut);
}

String? _sameLineValue(
    String text,
    List<String> labels,
    bool Function(String) ok,
    ) {
  for (final label in labels) {
    for (final m in _labelRegex(label).allMatches(text)) {
      final rest =
      text.substring(m.end).replaceFirst(RegExp(r'^[\s:.\-]+'), '');
      // "SURNAME / JINA LA UKOO": a bilingual label, not a value.
      if (rest.isEmpty || rest.startsWith('/') || rest.startsWith('|')) continue;
      final value = _cutAtNextLabel(rest).trim();
      if (ok(value)) return value;
    }
  }
  return null;
}

Iterable<String> _headParts(String head) => head
    .split(RegExp(r'[/|]'))
    .map((p) => p.trim())
    .where((p) => p.isNotEmpty);

double _verticalOverlap(Rect a, Rect b) {
  final overlap = math.min(a.bottom, b.bottom) - math.max(a.top, b.top);
  final smaller = math.min(a.height, b.height);
  return smaller <= 0 ? 0 : overlap / smaller;
}

int _digitCount(String v) => RegExp(r'\d').allMatches(v).length;

bool _looksLikeName(String v) => _digitCount(v) == 0;
enum Placement { below, right }

String? valueFor(
    OcrDocument doc,
    List<String> labels, {
      double threshold = 0.8,
      Placement prefer = Placement.below,
      bool Function(String value)? accept,
      RegExp? fallback,
    }) {
  bool ok(String v) => v.isNotEmpty && (accept?.call(v) ?? true);

  for (final line in doc.lines) {
    final value = _sameLineValue(line.text, labels, ok);
    if (value != null) return value;
  }

  for (final line in doc.lines) {
    final colon = line.text.indexOf(':');
    final head = colon == -1 ? line.text : line.text.substring(0, colon);
    final matches = _headParts(head)
        .any((part) => labels.any((l) => similarity(part, l) >= threshold));
    if (!matches) continue;

    final maxGap = line.box.height * 3;
    final below = doc.lines
        .where((o) =>
    !identical(o, line) &&
        o.box.top >= line.box.bottom - 4 &&
        o.box.top - line.box.bottom <= maxGap &&
        o.box.left < line.box.right &&
        o.box.right > line.box.left &&
        !_looksLikeLabel(o.text) &&
        ok(o.text.trim()))
        .toList()
      ..sort((a, b) => a.box.top.compareTo(b.box.top));

    final right = doc.lines
        .where((o) =>
    !identical(o, line) &&
        o.box.left >= line.box.right - 4 &&
        _verticalOverlap(o.box, line.box) > 0.4 &&
        !_looksLikeLabel(o.text) &&
        ok(o.text.trim()))
        .toList()
      ..sort((a, b) => a.box.left.compareTo(b.box.left));

    final ordered = prefer == Placement.right
        ? [...right, ...below]
        : [...below, ...right];
    if (ordered.isNotEmpty) return ordered.first.text.trim();
  }

  if (fallback != null) {
    final hits = doc.lines
        .map((l) => l.text.replaceAll(RegExp(r'\s'), ''))
        .where(fallback.hasMatch)
        .toSet();
    if (hits.length == 1) return hits.first;
  }
  return null;
}

class IdParser {
  const IdParser();

  IdFields parse(OcrDocument doc) => IdFields(
    surname: valueFor(doc, surnameLabels, accept: _looksLikeName),
    givenNames: valueFor(doc, givenNameLabels, accept: _looksLikeName),
    // The ID number's label sits beside its value, so look right first.
    idNumber: valueFor(
      doc,
      idNumberLabels,
      prefer: Placement.right,
      accept: (v) => _digitCount(v) >= 6,
      fallback: idNumberPattern,
    ),
    dateOfBirth: valueFor(
      doc,
      dateOfBirthLabels,
      accept: (v) => _digitCount(v) >= 4,
    ),
    districtOfBirth:
    valueFor(doc, districtOfBirthLabels, accept: _looksLikeName),
  );
}