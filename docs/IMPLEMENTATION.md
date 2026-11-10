# Implementation guide (step by step)

A simple recipe a teammate or a model can follow to rebuild the demo. Follow official docs for the
`camera`, `flutter_bloc` and `google_mlkit_text_recognition` packages; check their READMEs for current
setup requirements. Each step ends in a state you can run, and can be committed and tagged.

| Step | Tag | Goal | Files |
|---|---|---|---|
| 0 | `step-0-scaffold` | Project runs with an empty page | `pubspec.yaml`, `lib/main.dart`, `lib/app.dart` (placeholder home), `setup.sh` |
| 1 | `step-1-camera` | Camera preview and capture | `presentation/view/scan_page.dart` (camera only) |
| 2 | `step-2-ocr-service` | ML Kit behind an interface | `domain/ocr_document.dart`, `domain/ocr_service.dart`, `data/mlkit_ocr_service.dart` |
| 3 | `step-3-bloc-and-ui` | BLoC, states, result page, cancel/recovery | `presentation/bloc/*`, `view/result_view.dart`, `scan_bloc_test.dart` |
| 4 | `step-4-parser` | Raw lines to fields, fuzzy labels | `domain/id_fields.dart`, `domain/id_parser.dart`, `id_parser_test.dart` |
| 5 | `step-5-overlay` | Boxes on the photo, coordinate mapping | `presentation/widgets/box_overlay.dart`, `box_overlay_test.dart` |
| final | `final` | Preprocessing experiment, CI, docs | `data/preprocess.dart`, `.github/workflows/ci.yml`, `docs/*` |

## Rules for each step

1. Keep ML Kit imports inside `data/`.
2. Use `flutter_bloc` with sealed events and states (`Equatable` on states).
3. Run `flutter analyze` and `flutter test` before committing.
4. Never use a real ID. Use `samples/fictional_id_front.png`.
5. Do not add image preprocessing by default. Measure first.

## Step details

**0. Scaffold.** `flutter create . --platforms=android`, add the CAMERA permission, set `minSdk` per the package READMEs.

**1. Camera.** Build a `CameraController` (back camera, `ResolutionPreset.high`, no audio), show `CameraPreview`, capture with `takePicture()`. Handle a missing camera and a denied permission with a visible message.

**2. OCR service.** Domain: `OcrLine(text, box)` and `OcrDocument(lines, imageSize)`. Interface `OcrService.recognize(path)`. Data: `TextRecognizer(script: latin)`, `processImage(InputImage.fromFilePath(path))`, flatten blocks to lines, read the image size with `decodeImageFromList`.

**3. BLoC.** Events: `ScanCaptured(path)`, `ScanCancelled`. States: `ScanIdle`, `ScanProcessing`, `ScanSuccess`, `ScanFailure`. Use a request id so a cancelled scan's late result is ignored. Test success, failure and cancel-while-processing with `bloc_test` and `mocktail`.

**4. Parser.** Levenshtein-based `similarity` on normalized strings, `valueFor(doc, labels)` (value after a colon, else the nearest line below that overlaps horizontally), threshold 0.8. Unit-test with `samples/messy_labels.txt`.

**5. Overlay.** `mapRect(rect, imageSize, widgetSize)` for `BoxFit.contain`; paint with a `CustomPainter` over `Image.file`. Test `mapRect` with a wide image in a square widget.

**Final.** Optional `--dart-define=PREPROCESS=true` experiment; benchmark 8 to 10 photos (original vs preprocessed) and record real counts for the talk.

## Not included yet

A gallery-picker fallback (`image_picker`) and iOS support. Add them only if the talk needs them.
