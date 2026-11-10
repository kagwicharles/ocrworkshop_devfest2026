import 'id_fields.dart';
import 'verification_result.dart';

/// Server-side verification of what the phone extracted.
/// Receives only the text fields, never the photo.
abstract interface class VerificationService {
  Future<VerificationResult> verify(IdFields fields);
}