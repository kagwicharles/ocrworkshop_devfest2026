import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../domain/ocr_document.dart';

/// Maps a rect from IMAGE pixel space to WIDGET space, assuming the image is
/// drawn with BoxFit.contain (centered, uniformly scaled).
Rect mapRect(Rect r, Size image, Size widget) {
  final scale = math.min(widget.width / image.width, widget.height / image.height);
  final dx = (widget.width - image.width * scale) / 2;
  final dy = (widget.height - image.height * scale) / 2;
  return Rect.fromLTRB(
    r.left * scale + dx,
    r.top * scale + dy,
    r.right * scale + dx,
    r.bottom * scale + dy,
  );
}

class BoxOverlay extends StatelessWidget {
  const BoxOverlay({
    super.key,
    required this.imagePath,
    required this.document,
    this.showBoxes = true,
    this.swapSize = false,
  });

  final String imagePath;
  final OcrDocument document;
  final bool showBoxes;

  /// Demo switch: swaps image width/height to show the coordinate-space bug.
  final bool swapSize;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.file(File(imagePath), fit: BoxFit.contain),
        if (showBoxes)
          CustomPaint(painter: _BoxPainter(document, swapSize: swapSize)),
      ],
    );
  }
}

class _BoxPainter extends CustomPainter {
  _BoxPainter(this.document, {required this.swapSize});

  final OcrDocument document;
  final bool swapSize;

  @override
  void paint(Canvas canvas, Size size) {
    final image = swapSize
        ? Size(document.imageSize.height, document.imageSize.width)
        : document.imageSize;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.redAccent;
    for (final line in document.lines) {
      canvas.drawRect(mapRect(line.box, image, size), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BoxPainter old) =>
      old.document != document || old.swapSize != swapSize;
}