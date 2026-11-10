import 'dart:ui';

import 'package:equatable/equatable.dart';

/// One recognized line of text. [box] is in IMAGE pixel space.
class OcrLine extends Equatable {
  const OcrLine(this.text, this.box);

  final String text;
  final Rect box;

  @override
  List<Object?> get props => [text, box];
}

/// Everything the rest of the app knows about an OCR result.
/// No ML Kit types leak out of the data layer.
class OcrDocument extends Equatable {
  const OcrDocument(this.lines, this.imageSize);

  final List<OcrLine> lines;
  final Size imageSize;

  @override
  List<Object?> get props => [lines, imageSize];
}