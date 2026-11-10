/// Optional server used ONLY to verify extracted text fields.
/// OCR always runs on the phone; the photo never leaves it.
///
///   flutter run --dart-define=VERIFY_SERVER_URL=http://<laptop-ip>:8000/verify
const verifyServerUrl = String.fromEnvironment('VERIFY_SERVER_URL');
const bool verificationConfigured = verifyServerUrl != '';