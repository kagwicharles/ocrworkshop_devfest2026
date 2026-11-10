import 'dart:convert';
import 'dart:io';

import '../domain/id_fields.dart';
import '../domain/verification_result.dart';
import '../domain/verification_service.dart';

/// Sends the on-device OCR fields to YOUR backend, which compares them with
/// the IPRS record. The app never talks to IPRS and holds no IPRS credentials.
///
/// Request : {"surname": "...", "givenNames": "...", "idNumber": "...", "dateOfBirth": "..."}
/// Response: {"verified": true, "message": "...",
///            "fields": {"surname": {"match": true, "score": 0.97}, ...}}
/// See tools/iprs_mock_server.py for a reference implementation.
class HttpVerificationService implements VerificationService {
  HttpVerificationService(this.endpoint,
      {this.timeout = const Duration(seconds: 10)});

  final Uri endpoint;
  final Duration timeout;

  @override
  Future<VerificationResult> verify(IdFields fields) async {
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      final request = await client.postUrl(endpoint);
      request.headers.contentType = ContentType.json;
      request.add(utf8.encode(jsonEncode({
        'surname': fields.surname,
        'givenNames': fields.givenNames,
        'idNumber': fields.idNumber,
        'dateOfBirth': fields.dateOfBirth,
      })));
      final response = await request.close().timeout(timeout);
      if (response.statusCode != 200) {
        throw HttpException('Verification server returned ${response.statusCode}');
      }
      final body = await response.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;
      final raw = json['fields'] as Map<String, dynamic>? ?? {};
      return VerificationResult(
        verified: json['verified'] as bool,
        message: json['message'] as String? ?? '',
        fields: {
          for (final e in raw.entries)
            e.key: FieldMatch(
              match: (e.value as Map<String, dynamic>)['match'] as bool,
              score: ((e.value as Map<String, dynamic>)['score'] as num?)
                  ?.toDouble() ??
                  1,
            ),
        },
      );
    } finally {
      client.close(force: true);
    }
  }
}

/// Used when no verification server is configured.
class DisabledVerificationService implements VerificationService {
  const DisabledVerificationService();

  @override
  Future<VerificationResult> verify(IdFields fields) =>
      throw StateError('No verification server configured');
}