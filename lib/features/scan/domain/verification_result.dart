import 'package:equatable/equatable.dart';

/// How one extracted field compared with the IPRS record.
class FieldMatch extends Equatable {
  const FieldMatch({required this.match, this.score = 1});

  final bool match;

  /// 0.0 to 1.0. Names are matched fuzzily (OCR makes small mistakes),
  /// so 0.93 can still be a match. ID number and date of birth are exact.
  final double score;

  @override
  List<Object?> get props => [match, score];
}

/// The server's verdict from comparing the on-device OCR result with IPRS.
/// IPRS data itself never reaches the phone: only this verdict does.
class VerificationResult extends Equatable {
  const VerificationResult({
    required this.verified,
    required this.message,
    this.fields = const {},
  });

  final bool verified;
  final String message;

  /// Keyed by field name (surname, givenNames, idNumber, dateOfBirth).
  final Map<String, FieldMatch> fields;

  @override
  List<Object?> get props => [verified, message, fields];
}