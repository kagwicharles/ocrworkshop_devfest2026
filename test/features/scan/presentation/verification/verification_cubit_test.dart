import 'package:bloc_test/bloc_test.dart';
import 'package:ocr_workshop/features/scan/domain/id_fields.dart';
import 'package:ocr_workshop/features/scan/domain/verification_result.dart';
import 'package:ocr_workshop/features/scan/domain/verification_service.dart';
import 'package:ocr_workshop/features/scan/presentation/verification/verification_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

class _Fake implements VerificationService {
  _Fake({this.fail = false});
  final bool fail;
  IdFields? received;

  @override
  Future<VerificationResult> verify(IdFields fields) async {
    received = fields;
    if (fail) throw Exception('offline');
    return const VerificationResult(
      verified: true,
      message: 'ok',
      fields: {'idNumber': FieldMatch(match: true)},
    );
  }
}

void main() {
  const fields = IdFields(idNumber: 'TL-1234567', surname: 'TESTER');

  blocTest<VerificationCubit, VerificationState>(
    'sends the OCR fields and emits the verdict',
    build: () => VerificationCubit(_Fake()),
    act: (cubit) => cubit.verify(fields),
    expect: () => [
      const VerificationInProgress(),
      const VerificationDone(VerificationResult(
        verified: true,
        message: 'ok',
        fields: {'idNumber': FieldMatch(match: true)},
      )),
    ],
  );

  blocTest<VerificationCubit, VerificationState>(
    'an unreachable server is a recoverable failure',
    build: () => VerificationCubit(_Fake(fail: true)),
    act: (cubit) => cubit.verify(fields),
    expect: () => [
      const VerificationInProgress(),
      const VerificationFailed(VerificationCubit.unreachableMessage),
    ],
  );

  test('nothing is sent until verify() is called', () {
    final service = _Fake();
    VerificationCubit(service);
    expect(service.received, isNull);
  });
}