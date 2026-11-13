import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/scan_state.dart';
import '../settings/demo_settings_cubit.dart';
import '../widgets/box_overlay.dart';

class ResultView extends StatelessWidget {
  const ResultView({
    super.key,
    required this.state,
    required this.onScanAgain,
    required this.onCompare,
  });

  final ScanSuccess state;
  final VoidCallback onScanAgain;
  final VoidCallback onCompare;

  @override
  Widget build(BuildContext context) {
    final f = state.fields;
    final settings = context.watch<DemoSettingsCubit>().state;

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: BoxOverlay(
                imagePath: state.imagePath,
                document: state.document,
                showBoxes: settings.showBoxes,
                swapSize: settings.swapSize,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                avatar: Icon(Icons.smartphone, size: 18),
                label: Text('Read on this device'),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: ListView(
              children: [
                _FieldTile('Full Names', f.surname),
                _FieldTile('District of Birth', f.districtOfBirth),
                _FieldTile('ID number', f.idNumber),
                _FieldTile('Date of birth', f.dateOfBirth),

                ExpansionTile(
                  title: Text('Raw lines (${state.document.lines.length})'),
                  children: [
                    for (final line in state.document.lines)
                      ListTile(dense: true, title: Text(line.text)),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCompare,
                    icon: const Icon(Icons.navigate_next),
                    label: const Text('Next'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onScanAgain,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Scan again'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldTile extends StatelessWidget {
  const _FieldTile(this.label, this.value);

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(value == null ? Icons.help_outline : Icons.check_circle_outline),
      title: Text(label),
      subtitle: Text(value ?? 'Not found'),
    );
  }
}