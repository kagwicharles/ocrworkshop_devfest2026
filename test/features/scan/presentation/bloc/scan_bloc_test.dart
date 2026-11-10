import 'dart:async';
import 'dart:ui';

import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ocr_workshop/features/scan/domain/id_fields.dart';
import 'package:ocr_workshop/features/scan/domain/id_parser.dart';
import 'package:ocr_workshop/features/scan/domain/ocr_document.dart';
import 'package:ocr_workshop/features/scan/domain/ocr_service.dart';
import 'package:ocr_workshop/features/scan/presentation/bloc/scan_bloc.dart';

class _MockOcr extends Mock implements OcrService {}

void main() {
  const document = OcrDocument([], Size(100, 100));
  late _MockOcr ocr;

  setUp(() => ocr = _MockOcr());

  blocTest<ScanBloc, ScanState>(
    'emits processing then success',
    build: () {
      when(() => ocr.recognize(any())).thenAnswer((_) async => document);
      return ScanBloc(ocr, const IdParser());
    },
    act: (bloc) => bloc.add(const ScanCaptured('/tmp/a.jpg')),
    expect: () => [
      const ScanProcessing(),
      const ScanSuccess('/tmp/a.jpg', document, IdFields()),
    ],
  );

  blocTest<ScanBloc, ScanState>(
    'emits a recoverable failure when OCR throws',
    build: () {
      when(() => ocr.recognize(any())).thenAnswer((_) async => throw Exception('boom'));
      return ScanBloc(ocr, const IdParser());
    },
    act: (bloc) => bloc.add(const ScanCaptured('/tmp/a.jpg')),
    expect: () => [
      const ScanProcessing(),
      const ScanFailure(ScanBloc.unreadableMessage),
    ],
  );

  blocTest<ScanBloc, ScanState>(
    'cancel while processing: the late result is ignored',
    build: () {
      final completer = Completer<OcrDocument>();
      when(() => ocr.recognize(any())).thenAnswer((_) => completer.future);
      addTearDown(() {
        if (!completer.isCompleted) completer.complete(document);
      });
      return ScanBloc(ocr, const IdParser());
    },
    act: (bloc) async {
      bloc.add(const ScanCaptured('/tmp/a.jpg'));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const ScanCancelled());
      await Future<void>.delayed(Duration.zero);
    },
    wait: const Duration(milliseconds: 50),
    expect: () => [const ScanProcessing(), const ScanIdle()],
  );
}
