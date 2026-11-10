import 'package:equatable/equatable.dart';

import '../../domain/id_fields.dart';
import '../../domain/ocr_document.dart';

sealed class ScanState extends Equatable {
  const ScanState();

  @override
  List<Object?> get props => [];
}

class ScanIdle extends ScanState {
  const ScanIdle();
}

class ScanProcessing extends ScanState {
  const ScanProcessing();
}

class ScanSuccess extends ScanState {
  const ScanSuccess(this.imagePath, this.document, this.fields);

  final String imagePath;
  final OcrDocument document;
  final IdFields fields;

  @override
  List<Object?> get props => [imagePath, document, fields];
}

class ScanFailure extends ScanState {
  const ScanFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
