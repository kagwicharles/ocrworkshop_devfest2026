# ocr_workshop

Demo app for the **DevFest Nairobi** workshop on on-device OCR with Flutter and Google ML Kit.

Take a photo of an ID card. The phone reads it **on the device** (no internet needed), pulls out the fields, and draws a box around every line of text it found.

> The sample card in `samples/` is **fictional**. Never scan a real person's ID in a demo.

## What it shows

- Camera to text flow, with state managed by BLoC (including cancel and retry)
- On-device text recognition with Google ML Kit
- Turning raw text into fields (surname, given names, ID number, date of birth) with fuzzy label matching
- Drawing boxes over the photo, and the coordinate-space bug that goes with it
- A live test of whether image preprocessing helps or hurts
- On-device vs server OCR, with the server only used when you allow it

OCR reads text. It does **not** check that a document is genuine or that the person holding it is the owner.

## Before you start

You need:

- **Flutter SDK** (stable channel). Run `flutter doctor` and fix anything it flags for Android.
- **An Android phone** with USB debugging turned on (recommended). An emulator works too, but use the gallery button because emulator cameras are poor.
- **Git** and a terminal.
- **Python 3** only if you want the optional server demo.

## Run it in 5 steps

### 1. Get the code

```bash
git clone <your-repo-url> ocr_workshop
cd ocr_workshop
```

### 2. One-time setup

This repo contains the app code. The Android platform folder is generated once.

**macOS, Linux, or Git Bash on Windows:**

```bash
./setup.sh
```

The script creates the `android/` folder, adds the camera permission, and runs `flutter pub get`.

**Windows PowerShell (or if the script fails), do it by hand:**

1. Back up `pubspec.yaml` and the `lib/` folder (copy them somewhere safe).
2. Run:
   ```bash
   flutter create . --platforms=android --project-name ocr_workshop --org ke.devfest
   ```
3. Restore your `pubspec.yaml` and `lib/` from the backup if they were changed.
4. Delete `test/widget_test.dart` if it mentions `MyApp`.
5. Open `android/app/src/main/AndroidManifest.xml` and add this line just above `<application`:
   ```xml
   <uses-permission android:name="android.permission.CAMERA"/>
   ```
6. Run `flutter pub get`.

### 3. Check the Android minimum version

If the build stops with a `minSdk` error, open `android/app/build.gradle.kts` (or `build.gradle`) and set `minSdk` to the number the error asks for. The camera and ML Kit packages decide the minimum, and the strictest one wins.

### 4. Connect your phone

1. On the phone: Settings, About phone, tap **Build number** 7 times, then turn on **USB debugging** in Developer options.
2. Plug it in and accept the prompt on the phone.
3. Check that Flutter sees it:
   ```bash
   flutter devices
   ```

### 5. Run

```bash
flutter run
```

Allow the camera permission when asked. The first build takes a few minutes.

## Try it

1. Open `samples/fictional_id_front.png` on a laptop screen at full brightness, or print it.
2. Fill the frame in the app with the card and tap the white shutter button.
3. You should see the card photo with red boxes and the four fields filled in.
4. **Offline test:** turn on airplane mode and scan again. It still works, because recognition runs on the phone.

No camera handy? Tap the gallery button next to the shutter and pick a photo instead.

## Demo controls

Tap the **tune icon** in the top bar to flip these live:

| Switch | What it does |
|---|---|
| Preprocess before OCR | Grayscale and contrast boost before reading. An experiment: measure it, do not assume it helps. |
| Show recognized boxes | Draws a box around each recognized line. |
| Break the overlay | Swaps the image width and height so the boxes land in the wrong place. Turn it off to fix. |
| Allow server fallback | If the phone reads too little, upload the photo to your OCR server. Off by default: nothing leaves the device. |

On the result screen, tap **Compare** to run the same photo through several pipelines and see lines found, fields found (out of 4) and time for each. Judge a pipeline on several photos, not one. The first scan after launch is slower because the model warms up.

You can also start with a switch already on:

```bash
flutter run --dart-define=PREPROCESS=true
flutter run --dart-define=SWAP_SIZE=true
```

## Optional: server OCR demo

This shows the on-device vs server trade-off. Skip it if you only want the on-device demo.

1. Install the Tesseract program on your laptop, then:
   ```bash
   pip install pillow pytesseract
   python3 tools/ocr_server.py
   ```
2. Put the phone and laptop on the same Wi-Fi (or use your phone's hotspot) and find the laptop's IP address.
3. For this demo only, open `android/app/src/main/AndroidManifest.xml` and add:
    - `<uses-permission android:name="android.permission.INTERNET"/>` above `<application`
    - `android:usesCleartextTraffic="true"` inside the `<application` tag
4. Run:
   ```bash
   flutter run --dart-define=OCR_SERVER_URL=http://<laptop-ip>:8000/ocr
   ```
5. In the demo controls, turn on **Allow server fallback**. Scan something the phone reads poorly and the result screen will say **Read on the server**.

Use a real HTTPS server and remove the cleartext setting for anything beyond a demo.

## Run the tests

```bash
flutter analyze
flutter test
```

The tests cover the label matching, the BLoC (success, failure, cancel while processing), the box mapping, the comparison and the server fallback rules.

## How it is organized

```
lib/
  main.dart, app.dart, config.dart
  features/scan/
    domain/        OcrDocument, OcrService (interface), IdParser (fuzzy labels), OcrComparator
    data/          MlKitOcrService, HttpOcrService, ConfigurableOcrService, preprocess.dart
    presentation/  bloc/ (ScanBloc), settings/, view/ (ScanPage, ResultView), widgets/
test/              unit tests mirroring lib/
samples/           fictional ID card and messy label examples
tools/             ocr_server.py (optional server demo)
docs/              architecture, step-by-step build guide, troubleshooting
```

Rule of the design: ML Kit types never leave the `data/` folder, so the engine can be swapped without touching the BLoC or the screens. More in `docs/architecture.md` and `docs/IMPLEMENTATION.md`.

## Troubleshooting

| Problem | Fix |
|---|---|
| `flutter devices` shows no phone | Re-plug the cable, accept the USB debugging prompt, try another cable. |
| "Camera unavailable" on screen | Allow the camera permission in Android settings, check the manifest line from step 2, restart the app. |
| Build fails on `minSdk` | Raise `minSdk` as described in step 3. |
| Boxes are in the wrong place | The "Break the overlay" switch may be on. Turn it off. If it is off, see `docs/troubleshooting.md` on image rotation. |
| Fields show "Not found" | Open "Raw lines" on the result screen to see what was read, then add the misread label to `samples/messy_labels.txt` and a test. |
| Server fallback never triggers | It needs `OCR_SERVER_URL`, the switch turned on, and a scan where the phone reads fewer than 4 lines. |
| `./setup.sh` not found or not allowed | Run `bash setup.sh`, or use the manual steps in step 2. |

More in `docs/troubleshooting.md`.

## Status

Built without a Flutter SDK on hand, so the Dart code has not been compiled yet. On first run, do `flutter analyze` and `flutter test` and fix anything they report before rehearsing. Commit the generated `pubspec.lock` once it works.

## License

MIT