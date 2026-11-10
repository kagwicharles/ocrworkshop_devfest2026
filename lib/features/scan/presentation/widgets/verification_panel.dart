import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config.dart';
import '../../domain/id_fields.dart';
import '../../domain/verification_result.dart';
import '../verification/verification_cubit.dart';

/// Optional step after on-device extraction: the server compares what the
/// phone read with the IPRS record and returns only a match verdict.
class VerificationPanel extends StatelessWidget {
  const VerificationPanel({super.key, required this.fields});

  final IdFields fields;

  static const _labels = {
    'surname': 'Surname',
    'givenNames': 'Given names',
    'idNumber': 'ID number',
    'dateOfBirth': 'Date of birth',
  };

  Map<String, String?> get _values => {
    'surname': fields.surname,
    'givenNames': fields.givenNames,
    'idNumber': fields.idNumber,
    'dateOfBirth': fields.dateOfBirth,
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: BlocBuilder<VerificationCubit, VerificationState>(
          builder: (context, state) => switch (state) {
            VerificationIdle() => _idle(context, textTheme),
            VerificationInProgress() => const Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                SizedBox(width: 12),
                Text('Matching against IPRS...'),
              ],
            ),
            final VerificationDone d => _done(context, d.result, textTheme),
            final VerificationFailed f => _failed(context, f, textTheme),
          },
        ),
      ),
    );
  }

  Widget _idle(BuildContext context, TextTheme textTheme) {
    final canVerify = verificationConfigured && fields.idNumber != null;
    final hint = !verificationConfigured
        ? 'No verification server configured. Start the app with '
        '--dart-define=VERIFY_SERVER_URL=...'
        : fields.idNumber == null
        ? 'An ID number is needed to match against IPRS.'
        : 'Sends the text read on this phone to the server, which compares it '
        'with IPRS. The photo never leaves this phone, and IPRS data is '
        'not sent back: only the match result.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Verify against IPRS (optional)', style: textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(hint, style: textTheme.bodySmall),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(
          onPressed: canVerify
              ? () => context.read<VerificationCubit>().verify(fields)
              : null,
          icon: const Icon(Icons.verified_user_outlined),
          label: const Text('Verify with IPRS'),
        ),
      ],
    );
  }

  Widget _done(BuildContext context, VerificationResult r, TextTheme textTheme) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              r.verified ? Icons.verified : Icons.gpp_bad_outlined,
              color: r.verified ? scheme.primary : scheme.error,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                r.verified ? 'Matches IPRS' : 'Does not match IPRS',
                style: textTheme.titleSmall,
              ),
            ),
          ],
        ),
        if (r.message.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(r.message, style: textTheme.bodySmall),
        ],
        const SizedBox(height: 8),
        for (final e in r.fields.entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Icon(
                  e.value.match ? Icons.check_circle_outline : Icons.cancel_outlined,
                  size: 18,
                  color: e.value.match ? scheme.primary : scheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('${_labels[e.key] ?? e.key}: ${_values[e.key] ?? ''}'),
                ),
                if (e.value.match && e.value.score < 1)
                  Text('${(e.value.score * 100).round()}%',
                      style: textTheme.bodySmall),
              ],
            ),
          ),
      ],
    );
  }

  Widget _failed(BuildContext context, VerificationFailed f, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(f.message, style: textTheme.bodyMedium),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => context.read<VerificationCubit>().verify(fields),
          icon: const Icon(Icons.refresh),
          label: const Text('Try again'),
        ),
      ],
    );
  }
}