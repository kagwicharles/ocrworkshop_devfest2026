import 'ocr_document.dart';

abstract interface class OcrService {
  Future<OcrDocument> recognize(String imagePath);
  Future<void> dispose();
}
