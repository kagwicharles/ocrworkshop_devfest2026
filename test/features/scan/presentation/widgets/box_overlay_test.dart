import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ocr_workshop/features/scan/presentation/widgets/box_overlay.dart';

void main() {
  test('letterboxes a wide image inside a square widget', () {
    final mapped = mapRect(
      const Rect.fromLTRB(0, 0, 1000, 500),
      const Size(1000, 500),
      const Size(500, 500),
    );
    expect(mapped, const Rect.fromLTRB(0, 125, 500, 375));
  });

  test('scales and offsets a box inside the image', () {
    final mapped = mapRect(
      const Rect.fromLTRB(100, 100, 200, 200),
      const Size(1000, 500),
      const Size(500, 500),
    );
    expect(mapped, const Rect.fromLTRB(50, 175, 100, 225));
  });
}
