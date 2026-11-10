import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/id_fields.dart';
import '../../domain/ocr_comparator.dart';

/// Runs the photo through every OCR variant and shows the numbers.
Future<void> showCompareSheet(BuildContext context, String imagePath) {
  final future = context.read<OcrComparator>().compare(imagePath);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: FutureBuilder<List<VariantResult>>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Running each variant on this photo...'),
                  ],
                ),
              );
            }
            if (snapshot.hasError || snapshot.data == null) {
              return const Text('Comparison failed. Try again.');
            }
            return _ResultsTable(results: snapshot.data!);
          },
        ),
      ),
    ),
  );
}

class _ResultsTable extends StatelessWidget {
  const _ResultsTable({required this.results});

  final List<VariantResult> results;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Same photo, different pipelines',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Variant')),
              DataColumn(label: Text('Lines'), numeric: true),
              DataColumn(label: Text('Fields'), numeric: true),
              DataColumn(label: Text('Time'), numeric: true),
            ],
            rows: [
              for (final r in results)
                DataRow(cells: [
                  DataCell(Text(r.name)),
                  DataCell(Text(r.failed ? '-' : '${r.lineCount}')),
                  DataCell(Text(r.failed
                      ? 'failed'
                      : '${r.fieldsFound}/${IdFields.totalFields}')),
                  DataCell(Text(
                      r.failed ? '-' : '${r.elapsed.inMilliseconds} ms')),
                ]),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'More fields is better. Judge a variant on several photos, not one.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}