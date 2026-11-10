import '../domain/ocr_document.dart';
import '../domain/ocr_service.dart';

/// The service the BLoC talks to. OCR always runs on the device; the only
/// live choice is whether to run it on a preprocessed copy of the photo
/// (the "does preprocessing help?" experiment).
class ConfigurableOcrService implements OcrService {
  ConfigurableOcrService({
    required this.onDevice,
    required this.preprocessed,
    required this.usePreprocess,
  });

  final OcrService onDevice;
  final OcrService preprocessed;
  final bool Function() usePreprocess;

  @override
  Future<OcrDocument> recognize(String imagePath) =>
      (usePreprocess() ? preprocessed : onDevice).recognize(imagePath);

  /// The wrapped services are owned and released elsewhere.
  @override
  Future<void> dispose() async {}
}