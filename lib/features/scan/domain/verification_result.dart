import 'package:equatable/equatable.dart';

class FieldMatch extends Equatable {
  const FieldMatch({required this.match, this.score = 1});

  final bool match;

  final double score;

  @override
  List<Object?> get props => [match, score];
}

class VerificationResult extends Equatable {
  const VerificationResult({
    required this.verified,
    required this.message,
    this.fields = const {},
  });

  final bool verified;
  final String message;

  final Map<String, FieldMatch> fields;

  @override
  List<Object?> get props => [verified, message, fields];
}