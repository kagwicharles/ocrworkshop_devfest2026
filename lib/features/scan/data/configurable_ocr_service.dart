import '../domain/ocr_document.dart';
import '../domain/ocr_service.dart';

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

  @override
  Future<void> dispose() async {}
}