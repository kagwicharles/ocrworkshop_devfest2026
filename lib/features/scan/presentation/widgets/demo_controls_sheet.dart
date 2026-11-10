import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config.dart';
import '../settings/demo_settings_cubit.dart';

Future<void> showDemoControls(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => const _DemoControlsSheet(),
  );
}

class _DemoControlsSheet extends StatelessWidget {
  const _DemoControlsSheet();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DemoSettingsCubit>();
    return SafeArea(
      child: BlocBuilder<DemoSettingsCubit, DemoSettings>(
        builder: (context, s) => ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            const ListTile(
              title: Text('Demo controls'),
              subtitle: Text('Flip these live during the talk'),
            ),
            SwitchListTile(
              title: const Text('Preprocess before OCR'),
              subtitle: const Text('Grayscale + contrast. Experiment: measure it.'),
              value: s.preprocess,
              onChanged: cubit.setPreprocess,
            ),
            SwitchListTile(
              title: const Text('Show recognized boxes'),
              value: s.showBoxes,
              onChanged: cubit.setShowBoxes,
            ),
            SwitchListTile(
              title: const Text('Break the overlay (swap image size)'),
              subtitle: const Text('Shows the coordinate-space bug. Turn off to fix.'),
              value: s.swapSize,
              onChanged: cubit.setSwapSize,
            ),
            SwitchListTile(
              title: const Text('Allow server fallback'),
              subtitle: Text(
                serverConfigured
                    ? 'If the phone reads too little, upload the photo to the OCR server. Off = nothing leaves the device.'
                    : 'Start the app with --dart-define=OCR_SERVER_URL=... to enable.',
              ),
              value: s.allowServerFallback,
              onChanged: serverConfigured ? cubit.setAllowServerFallback : null,
            ),
          ],
        ),
      ),
    );
  }
}