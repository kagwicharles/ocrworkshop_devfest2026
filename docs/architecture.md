# Architecture

```
Camera (takePicture)
      |  file path
      v
ScanBloc  --ScanCaptured-->  OcrService (interface, domain)
   ^  |                           |
   |  |                  MlKitOcrService (data): TextRecognizer, image size
   |  v                           |
 ScanState  <--- OcrDocument -----+
   |          (lines + boxes in image pixels)
   v
IdParser (fuzzy labels) -> IdFields -> ResultView / BoxOverlay (mapRect)
```

## Rules

- ML Kit types never leave `data/`. The BLoC and UI only see `OcrDocument`.
- The BLoC depends on the `OcrService` interface, so tests use a mock and a server OCR can replace ML Kit.
- Cancel = ignore the late result. ML Kit cannot be cancelled mid-flight, so each scan has a request id and only the latest result may emit.
- Failure is a state (`ScanFailure`) with a way back (`ScanCancelled` returns to idle), not an exception that escapes.

## States

`ScanIdle` -> `ScanProcessing` -> `ScanSuccess | ScanFailure`; `ScanCancelled` from any state returns to `ScanIdle`.

## Coordinate spaces

ML Kit boxes are in image pixels. The photo is shown with `BoxFit.contain` in a different-sized widget, so
`mapRect` applies a uniform scale plus a centering offset. If the image carries a rotation flag, its stored
size can be swapped relative to what you see; verify on your device which size matches the boxes.
