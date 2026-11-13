import 'id_fields.dart';
import 'verification_result.dart';

abstract interface class VerificationService {
  Future<VerificationResult> verify(IdFields fields);
}