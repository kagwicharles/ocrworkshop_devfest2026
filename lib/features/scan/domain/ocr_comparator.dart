import 'package:equatable/equatable.dart';

import 'id_parser.dart';
import 'ocr_service.dart';

class VariantResult extends Equatable {
  const VariantResult({
    required this.name,
    required this.lineCount,
    required this.fieldsFound,
    required this.elapsed,
    this.failed = false,
  });

  const VariantResult.failed(this.name)
      : lineCount = 0,
        fieldsFound = 0,
        elapsed = Duration.zero,
        failed = true;

  final String name;
  final int lineCount;
  final int fieldsFound;
  final Duration elapsed;
  final bool failed;

  @override
  List<Object?> get props => [name, lineCount, fieldsFound, elapsed, failed];
}

/// Runs the same photo through several OCR variants so you can MEASURE
/// instead of guessing ("measure before you preprocess").
class OcrComparator {
  OcrComparator({required this.variants, required this.parser});

  /// Insertion order is the display order.
  final Map<String, OcrService> variants;
  final IdParser parser;

  Future<List<VariantResult>> compare(String imagePath) async {
    // Untimed warm-up so the first variant does not pay the model start-up cost.
    if (variants.isNotEmpty) {
      try {
        await variants.values.first.recognize(imagePath);
      } catch (_) {}
    }

    final results = <VariantResult>[];
    for (final entry in variants.entries) {
      final clock = Stopwatch()..start();
      try {
        final doc = await entry.value.recognize(imagePath);
        clock.stop();
        results.add(VariantResult(
          name: entry.key,
          lineCount: doc.lines.length,
          fieldsFound: parser.parse(doc).foundCount,
          elapsed: clock.elapsed,
        ));
      } catch (_) {
        results.add(VariantResult.failed(entry.key));
      }
    }
    return results;
  }
}