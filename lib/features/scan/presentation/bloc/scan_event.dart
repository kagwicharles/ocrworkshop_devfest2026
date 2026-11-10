sealed class ScanEvent {
  const ScanEvent();
}

/// A photo was captured and is ready to be read.
class ScanCaptured extends ScanEvent {
  const ScanCaptured(this.imagePath);
  final String imagePath;
}

/// Cancels an in-flight scan, or resets from success/failure to idle.
class ScanCancelled extends ScanEvent {
  const ScanCancelled();
}
