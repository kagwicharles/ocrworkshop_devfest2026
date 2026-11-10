#!/usr/bin/env bash
# One-time setup: generates the Android platform folder around the existing code.
set -euo pipefail
cd "$(dirname "$0")"

command -v flutter >/dev/null || { echo "Flutter SDK not found on PATH."; exit 1; }

# Keep our files safe in case `flutter create` touches them.
backup="$(mktemp -d)"
cp pubspec.yaml "$backup/pubspec.yaml"
cp -R lib "$backup/lib"

flutter create . --platforms=android --project-name ocr_workshop --org ke.devfest

cp "$backup/pubspec.yaml" pubspec.yaml
rm -rf lib && cp -R "$backup/lib" lib

# Drop the counter-app test that flutter create generates.
if [ -f test/widget_test.dart ] && grep -q "MyApp" test/widget_test.dart; then
  rm test/widget_test.dart
fi

# Add the camera permission if it is missing.
python3 - <<'PY'
import pathlib
p = pathlib.Path("android/app/src/main/AndroidManifest.xml")
s = p.read_text()
if "android.permission.CAMERA" not in s:
    s = s.replace("<application", '<uses-permission android:name="android.permission.CAMERA"/>\n    <application', 1)
    p.write_text(s)
    print("Added CAMERA permission to AndroidManifest.xml")
PY

flutter pub get

echo
echo "Done. Two things to check by hand:"
echo "  1. minSdk in android/app/build.gradle(.kts): must meet the READMEs of the"
echo "     camera and google_mlkit_text_recognition packages (strictest wins)."
echo "  2. Run: flutter analyze && flutter test && flutter run"
