import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/id_parser.dart';
import '../../domain/ocr_service.dart';
import 'scan_event.dart';
import 'scan_state.dart';

export 'scan_event.dart';
export 'scan_state.dart';

class ScanBloc extends Bloc<ScanEvent, ScanState> {
  ScanBloc(this._ocr, this._parser) : super(const ScanIdle()) {
    on<ScanCaptured>(_onCaptured);
    on<ScanCancelled>(_onCancelled);
  }

  static const unreadableMessage =
      'Could not read the document. Try more light and hold steady.';

  final OcrService _ocr;
  final IdParser _parser;

  int _requestId = 0;

  Future<void> _onCaptured(ScanCaptured event, Emitter<ScanState> emit) async {
    final id = ++_requestId;
    emit(const ScanProcessing());
    try {
      final document = await _ocr.recognize(event.imagePath);
      if (id != _requestId) return; // cancelled or superseded
      emit(ScanSuccess(event.imagePath, document, _parser.parse(document)));
    } catch (_) {
      if (id != _requestId) return;
      emit(const ScanFailure(unreadableMessage));
    }
  }

  void _onCancelled(ScanCancelled event, Emitter<ScanState> emit) {
    _requestId++; // invalidates any in-flight scan
    emit(const ScanIdle());
  }
}
