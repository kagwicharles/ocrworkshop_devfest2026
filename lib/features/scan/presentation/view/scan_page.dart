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

const double _cardAspect = 1.586;

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

  Size _viewportSize = Size.zero;

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
        viewSize: _viewportSize,
        frame: Offset.zero & _viewportSize,
      );
      bloc.add(ScanCaptured(croppedPath));
    } on CameraException {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not take the photo. Try again.')),
      );
    }
  }

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
            appBar: AppBar(title: const Text('KYC App')),
            body: ResultView(
              state: s,
              onScanAgain: () =>
                  context.read<ScanBloc>().add(const ScanCancelled()),
              onCompare: () => showCompareSheet(context, s.imagePath),
            ),
          ),
          final ScanFailure f => Scaffold(
            appBar: AppBar(title: const Text('KYC App')),
            body: _FailureView(
              message: f.message,
              onRetry: () =>
                  context.read<ScanBloc>().add(const ScanCancelled()),
            ),
          ),
          ScanIdle() => _buildCameraScaffold(context, processing: false),
          ScanProcessing() => _buildCameraScaffold(context, processing: true),
        },
      ),
    );
  }

  Widget _buildCameraScaffold(BuildContext context,
      {required bool processing}) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KYC'),
        actions: [
          if (_controller != null)
            IconButton(
              tooltip: _torchOn ? 'Turn torch off' : 'Turn torch on',
              onPressed: processing ? null : _toggleTorch,
              icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _HintText(processing: processing),
            ),
            const SizedBox(height: 12),
           Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AspectRatio(
                  aspectRatio: _cardAspect,
                  child: _buildViewport(context, processing: processing),
                ),
              ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
          ],
        ),
      ),
    );
  }

  Widget _buildViewport(BuildContext context, {required bool processing}) {
    final controller = _controller;
    final accent = Theme.of(context).colorScheme.primaryContainer;

    Widget content;
    if (controller == null) {
      content = const _CenteredMessage(
        icon: Icons.no_photography_outlined,
        text: 'No camera found on this device.',
      );
    } else {
      content = FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const _CenteredMessage(
              icon: Icons.videocam_off_outlined,
              text: 'Camera unavailable. Check the camera permission.',
            );
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          return LayoutBuilder(
            builder: (context, constraints) {
              _viewportSize = constraints.biggest;
              return Stack(
                fit: StackFit.expand,
                children: [
                  _CoverPreview(controller: controller),
                  if (processing) const ColoredBox(color: Colors.black45),
                  CustomPaint(
                    painter: _BracketsPainter(
                      color: processing ? accent : Colors.white,
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: ColoredBox(color: Colors.black, child: content),
    );
  }
}

/// Camera preview scaled to cover its box (no letterboxing, centre crop).
class _CoverPreview extends StatelessWidget {
  const _CoverPreview({required this.controller});

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

/// Rounded corner brackets drawn around the edge of the viewport.
class _BracketsPainter extends CustomPainter {
  _BracketsPainter({required this.color});

  final Color color;

  static const double _radius = 16;
  static const double _arm = 28;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final frame = (Offset.zero & size).deflate(2);
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
  bool shouldRepaint(covariant _BracketsPainter old) => old.color != color;
}

class _HintText extends StatelessWidget {
  const _HintText({required this.processing});

  final bool processing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          processing ? 'Hold still' : 'Fit your ID inside the frame',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          processing
              ? 'Reading the text on your phone'
              : 'Good light, no glare, text sharp',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
    final color = Theme.of(context).colorScheme.primary;
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
                border: Border.all(color: color, width: 4),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
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
      color: scheme.surfaceContainerHighest,
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

/// Shown inside the dark camera viewport when there is no usable camera.
class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: Colors.white70),
            const SizedBox(height: 8),
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