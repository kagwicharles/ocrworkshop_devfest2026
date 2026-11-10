/// Optional server OCR for the "on-device vs server" demo.
/// flutter run --dart-define=OCR_SERVER_URL=http://<laptop-ip>:8000/ocr
const ocrServerUrl = String.fromEnvironment('OCR_SERVER_URL');
const bool serverConfigured = ocrServerUrl != '';