sealed class ScanEvent {
  const ScanEvent();
}

class ScanCaptured extends ScanEvent {
  const ScanCaptured(this.imagePath);
  final String imagePath;
}

class ScanCancelled extends ScanEvent {
  const ScanCancelled();
}
