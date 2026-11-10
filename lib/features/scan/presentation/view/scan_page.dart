import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../util/card_cropper.dart';
import '../bloc/scan_bloc.dart';
import '../widgets/compare_sheet.dart';
import '../widgets/demo_controls_sheet.dart';
import 'result_view.dart';

/// ID-1 card ratio (credit card / most national ID cards): 85.6 x 54 mm.
const double _cardAspect = 1.586;

/// Where the card should sit on screen. Shared by the painter and the hint text.
Rect _frameRect(Size size) {
  final width = size.width * 0.88;
  final height = width / _cardAspect;
  return Rect.fromCenter(
    center: Offset(size.width / 2, size.height * 0.42),
    width: width,
    height: height,
  );
}

class ScanPage extends StatefulWidget {
  const ScanPage({super.key, required this.cameras});

  final List<CameraDescription> cameras;

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  CameraController? _controller;
  Future<void>? _initFuture;
  bool _torchOn = false;

  Size _viewSize = Size.zero;
  Rect _frame = Rect.zero;

  @override
  void initState() {
    super.initState();
    if (widget.cameras.isEmpty) return;
    final camera = widget.cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => widget.cameras.first,
    );
    final controller =
        CameraController(camera, ResolutionPreset.high, enableAudio: false);
    _controller = controller;
    _initFuture = controller.initialize();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture) {
      return;
    }
    HapticFeedback.mediumImpact();
    final bloc = context.read<ScanBloc>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final file = await controller.takePicture();
      final croppedPath = await cropToFrame(
        path: file.path,
        viewSize: _viewSize,
        frame: _frame,
      );
      bloc.add(ScanCaptured(croppedPath));
    } on CameraException {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not take the photo. Try again.')),
      );
    }
  }

  /// Fallback when the camera is awkward on stage: pick a photo instead.
  Future<void> _pickFromGallery() async {
    final bloc = context.read<ScanBloc>();
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    bloc.add(ScanCaptured(picked.path));
  }

  Future<void> _toggleTorch() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final next = !_torchOn;
    try {
      await controller.setFlashMode(next ? FlashMode.torch : FlashMode.off);
      if (mounted) setState(() => _torchOn = next);
    } on CameraException {
      // Device without a torch: ignore.
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        child: BlocBuilder<ScanBloc, ScanState>(
          builder: (context, state) => switch (state) {
            final ScanSuccess s => Scaffold(
                appBar: AppBar(title: const Text('Scan result')),
                body: ResultView(
                  state: s,
                  onScanAgain: () =>
                      context.read<ScanBloc>().add(const ScanCancelled()),
                  onCompare: () => showCompareSheet(context, s.imagePath),
                ),
              ),
            final ScanFailure f => Scaffold(
                appBar: AppBar(title: const Text('Scan ID')),
                body: _FailureView(
                  message: f.message,
                  onRetry: () =>
                      context.read<ScanBloc>().add(const ScanCancelled()),
                ),
              ),
            ScanIdle() => _buildCameraScaffold(context, processing: false),
            ScanProcessing() => _buildCameraScaffold(context, processing: true),
          },
        ));
  }

  Widget _buildCameraScaffold(BuildContext context,
      {required bool processing}) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Scan ID'),
        actions: [
          IconButton(
            tooltip: 'Demo controls',
            onPressed: () => showDemoControls(context),
            icon: const Icon(Icons.tune),
          ),
          if (_controller != null)
            IconButton(
              tooltip: _torchOn ? 'Turn torch off' : 'Turn torch on',
              onPressed: processing ? null : _toggleTorch,
              icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off),
            ),
        ],
      ),
      body: _buildCamera(context, processing: processing),
    );
  }

  Widget _buildCamera(BuildContext context, {required bool processing}) {
    final controller = _controller;
    if (controller == null) {
      return const _CenteredMessage(
        icon: Icons.no_photography_outlined,
        text: 'No camera found on this device.',
      );
    }
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _CenteredMessage(
            icon: Icons.videocam_off_outlined,
            text:
                'Camera unavailable. Check the camera permission and try again.',
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            final frame = _frameRect(size);
            final accent = Theme.of(context).colorScheme.primaryContainer;
            _viewSize = size;
            _frame = frame;
            return Stack(
              fit: StackFit.expand,
              children: [
                _FullScreenPreview(controller: controller),
                CustomPaint(
                  painter: _GuidePainter(
                    frame: frame,
                    color: processing ? accent : Colors.white,
                  ),
                ),
                Positioned(
                  left: 24,
                  right: 24,
                  top: frame.top - 76,
                  child: _HintText(processing: processing),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: processing
                            ? const _ProcessingPanel(key: ValueKey('busy'))
                            : _CaptureControls(
                                key: const ValueKey('ready'),
                                onCapture: _capture,
                                onGallery: _pickFromGallery,
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Camera preview scaled to cover the whole screen (no letterboxing).
class _FullScreenPreview extends StatelessWidget {
  const _FullScreenPreview({required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    final previewSize = controller.value.previewSize;
    if (previewSize == null) return CameraPreview(controller);
    // previewSize is reported in landscape; the app is used in portrait.
    return SizedBox.expand(
      child: ClipRect(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: previewSize.height,
            height: previewSize.width,
            child: CameraPreview(controller),
          ),
        ),
      ),
    );
  }
}

/// Dims everything outside the card frame and draws rounded corner brackets.
class _GuidePainter extends CustomPainter {
  _GuidePainter({required this.frame, required this.color});

  final Rect frame;
  final Color color;

  static const double _radius = 16;
  static const double _arm = 28;

  @override
  void paint(Canvas canvas, Size size) {
    final hole = Path()
      ..addRRect(
          RRect.fromRectAndRadius(frame, const Radius.circular(_radius)));
    final dim = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      hole,
    );
    canvas.drawPath(dim, Paint()..color = Colors.black.withAlpha(140));

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const r = _radius;
    const a = _arm;
    final l = frame.left, t = frame.top, rt = frame.right, b = frame.bottom;
    const radius = Radius.circular(r);

    final corners = Path()
      // top-left
      ..moveTo(l, t + r + a)
      ..lineTo(l, t + r)
      ..arcToPoint(Offset(l + r, t), radius: radius)
      ..lineTo(l + r + a, t)
      // top-right
      ..moveTo(rt - r - a, t)
      ..lineTo(rt - r, t)
      ..arcToPoint(Offset(rt, t + r), radius: radius)
      ..lineTo(rt, t + r + a)
      // bottom-right
      ..moveTo(rt, b - r - a)
      ..lineTo(rt, b - r)
      ..arcToPoint(Offset(rt - r, b), radius: radius)
      ..lineTo(rt - r - a, b)
      // bottom-left
      ..moveTo(l + r + a, b)
      ..lineTo(l + r, b)
      ..arcToPoint(Offset(l, b - r), radius: radius)
      ..lineTo(l, b - r - a);
    canvas.drawPath(corners, stroke);
  }

  @override
  bool shouldRepaint(covariant _GuidePainter old) =>
      old.frame != frame || old.color != color;
}

class _HintText extends StatelessWidget {
  const _HintText({required this.processing});

  final bool processing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          processing ? 'Hold still' : 'Fit your ID inside the frame',
          textAlign: TextAlign.center,
          style: textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          processing
              ? 'Reading the text on your phone'
              : 'Good light, no glare, text sharp',
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
        ),
      ],
    );
  }
}

class _CaptureControls extends StatelessWidget {
  const _CaptureControls({
    super.key,
    required this.onCapture,
    required this.onGallery,
  });

  final VoidCallback onCapture;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton.filledTonal(
          tooltip: 'Choose from gallery',
          onPressed: onGallery,
          icon: const Icon(Icons.photo_library_outlined),
        ),
        Semantics(
          button: true,
          label: 'Capture photo',
          child: GestureDetector(
            onTap: onCapture,
            child: Container(
              width: 76,
              height: 76,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        // Same width as the gallery button so the shutter stays centered.
        const SizedBox(width: 48),
      ],
    );
  }
}

class _ProcessingPanel extends StatelessWidget {
  const _ProcessingPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: scheme.surface,
      elevation: 4,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
        child: Row(
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Reading document...', style: textTheme.titleSmall),
                  Text(
                    'Processed on this device',
                    style: textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () =>
                  context.read<ScanBloc>().add(const ScanCancelled()),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.white70),
            const SizedBox(height: 16),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _FailureView extends StatelessWidget {
  const _FailureView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: scheme.errorContainer,
              child: Icon(
                Icons.document_scanner_outlined,
                size: 36,
                color: scheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Couldn't read that scan",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
