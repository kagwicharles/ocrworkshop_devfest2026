import 'ocr_document.dart';

/// Boundary between the app and whatever engine reads the image.
/// Swap the implementation (ML Kit, server OCR) without touching the BLoC.
abstract interface class OcrService {
  Future<OcrDocument> recognize(String imagePath);
  Future<void> dispose();
}
