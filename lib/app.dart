import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'config.dart';
import 'features/scan/data/configurable_ocr_service.dart';
import 'features/scan/data/http_ocr_service.dart';
import 'features/scan/data/mlkit_ocr_service.dart';
import 'features/scan/data/preprocess.dart';
import 'features/scan/domain/id_parser.dart';
import 'features/scan/domain/ocr_comparator.dart';
import 'features/scan/presentation/bloc/scan_bloc.dart';
import 'features/scan/presentation/settings/demo_settings_cubit.dart';
import 'features/scan/presentation/view/scan_page.dart';

class App extends StatelessWidget {
  const App({super.key, required this.cameras});

  final List<CameraDescription> cameras;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        // One ML Kit recognizer, shared by every pipeline, released once.
        RepositoryProvider<MlKitOcrService>(
          create: (_) => MlKitOcrService(),
          dispose: (service) => service.dispose(),
        ),
        RepositoryProvider<OcrComparator>(
          create: (context) {
            final mlkit = context.read<MlKitOcrService>();
            return OcrComparator(
              parser: const IdParser(),
              variants: {
                'Original': mlkit,
                'Grayscale + contrast': PreprocessingOcrService(
                    mlkit, PreprocessMode.grayscaleContrast),
                'Binarized + half size': PreprocessingOcrService(
                    mlkit, PreprocessMode.binarizeHalfSize),
                if (serverConfigured)
                  'Server OCR': HttpOcrService(Uri.parse(ocrServerUrl)),
              },
            );
          },
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => DemoSettingsCubit()),
          BlocProvider(
            create: (context) {
              final settings = context.read<DemoSettingsCubit>();
              final mlkit = context.read<MlKitOcrService>();
              final ocr = ConfigurableOcrService(
                onDevice: mlkit,
                preprocessed: PreprocessingOcrService(
                    mlkit, PreprocessMode.grayscaleContrast),
                server: serverConfigured
                    ? HttpOcrService(Uri.parse(ocrServerUrl))
                    : null,
                usePreprocess: () => settings.state.preprocess,
                allowServer: () => settings.state.allowServerFallback,
              );
              return ScanBloc(ocr, const IdParser());
            },
          ),
        ],
        child: MaterialApp(
          title: 'ID Scanner',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
          home: ScanPage(cameras: cameras),
        ),
      ),
    );
  }
}