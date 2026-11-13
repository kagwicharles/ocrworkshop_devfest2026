import 'dart:ui';

import 'package:equatable/equatable.dart';

class OcrLine extends Equatable {
  const OcrLine(this.text, this.box);

  final String text;
  final Rect box;

  @override
  List<Object?> get props => [text, box];
}

class OcrDocument extends Equatable {
  const OcrDocument(this.lines, this.imageSize);

  final List<OcrLine> lines;
  final Size imageSize;

  @override
  List<Object?> get props => [lines, imageSize];
}