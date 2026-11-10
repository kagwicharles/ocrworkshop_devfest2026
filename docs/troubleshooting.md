# Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| App shows "Camera unavailable" | Permission denied or missing from the manifest | Add the CAMERA permission, grant it in Android settings, relaunch |
| Build fails on `minSdk` | Package needs a higher minSdk than the template | Raise `minSdk` in `android/app/build.gradle(.kts)` to the strictest package requirement |
| Boxes drawn in the wrong place, as if rotated | Image width/height swapped vs displayed image (rotation flag) | Compare `document.imageSize` with the displayed photo; use the size that matches the boxes. `--dart-define=SWAP_SIZE=true` reproduces the bug on purpose |
| Fields come back "Not found" | Labels misread, or value not directly below its label | Print `document.lines`, add the misread label to `samples/messy_labels.txt` and a test, adjust synonyms or threshold |
| OCR is slow on the first scan | Model warm-up | Scan once before going on stage |
| Poor recognition in dim light | Low contrast, blur | More light, hold steady; do not rely on preprocessing, measure it first |
| `flutter test` fails on imports | `flutter pub get` not run, or name mismatch | Run `flutter pub get`; package name must be `ocr_workshop` |
| Mirroring lags on stage | USB or cable issue | Use scrcpy with a good cable; fall back to the recorded demo |
