import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/id_fields.dart';
import '../../domain/verification_result.dart';
import '../../domain/verification_service.dart';

sealed class VerificationState extends Equatable {
  const VerificationState();

  @override
  List<Object?> get props => [];
}

class VerificationIdle extends VerificationState {
  const VerificationIdle();
}

class VerificationInProgress extends VerificationState {
  const VerificationInProgress();
}

class VerificationDone extends VerificationState {
  const VerificationDone(this.result);
  final VerificationResult result;

  @override
  List<Object?> get props => [result];
}

class VerificationFailed extends VerificationState {
  const VerificationFailed(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

/// Verification is explicit: nothing is sent until the user taps Verify.
class VerificationCubit extends Cubit<VerificationState> {
  VerificationCubit(this._service) : super(const VerificationIdle());

  static const unreachableMessage = 'Could not reach the verification server.';

  final VerificationService _service;

  Future<void> verify(IdFields fields) async {
    emit(const VerificationInProgress());
    try {
      final result = await _service.verify(fields);
      if (isClosed) return;
      emit(VerificationDone(result));
    } catch (_) {
      if (isClosed) return;
      emit(const VerificationFailed(unreachableMessage));
    }
  }
}