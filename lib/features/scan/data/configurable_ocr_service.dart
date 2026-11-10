import '../domain/ocr_document.dart';
import '../domain/ocr_service.dart';

/// The service the BLoC talks to. Decides at call time, from live settings:
///  1. on-device, optionally on a preprocessed copy of the photo;
///  2. if the phone read too little AND the user allowed it, ask the server.
/// Server failures never break a scan: the on-device result is returned.
class ConfigurableOcrService implements OcrService {
  ConfigurableOcrService({
    required this.onDevice,
    required this.preprocessed,
    required this.usePreprocess,
    required this.allowServer,
    this.server,
    this.minLines = 4,
  });

  final OcrService onDevice;
  final OcrService preprocessed;
  final OcrService? server;
  final bool Function() usePreprocess;
  final bool Function() allowServer;

  /// Fewer lines than this counts as "the device could not read it".
  final int minLines;

  @override
  Future<OcrDocument> recognize(String imagePath) async {
    final primary = usePreprocess() ? preprocessed : onDevice;
    final doc = await primary.recognize(imagePath);

    final fallback = server;
    if (fallback != null && allowServer() && doc.lines.length < minLines) {
      try {
        return await fallback.recognize(imagePath);
      } catch (_) {
        return doc;
      }
    }
    return doc;
  }

  /// The wrapped services are owned and released elsewhere.
  @override
  Future<void> dispose() async {}
}