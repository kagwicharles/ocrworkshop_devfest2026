import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DemoSettings extends Equatable {
  const DemoSettings({
    this.preprocess = false,
    this.swapSize = false,
    this.showBoxes = true,
    this.allowServerFallback = false,
  });

  /// Grayscale + contrast before OCR (the "made it worse" experiment).
  final bool preprocess;

  /// Swaps image width/height in the overlay: shows the coordinate bug.
  final bool swapSize;

  /// Draw the recognized boxes over the photo.
  final bool showBoxes;

  /// Explicit consent to upload the photo to the OCR server when the phone
  /// reads too little. Off by default: nothing leaves the device.
  final bool allowServerFallback;

  DemoSettings copyWith({
    bool? preprocess,
    bool? swapSize,
    bool? showBoxes,
    bool? allowServerFallback,
  }) =>
      DemoSettings(
        preprocess: preprocess ?? this.preprocess,
        swapSize: swapSize ?? this.swapSize,
        showBoxes: showBoxes ?? this.showBoxes,
        allowServerFallback: allowServerFallback ?? this.allowServerFallback,
      );

  @override
  List<Object?> get props =>
      [preprocess, swapSize, showBoxes, allowServerFallback];
}

/// Runtime switches for the live demo. The old --dart-define flags still work
/// as the starting values.
class DemoSettingsCubit extends Cubit<DemoSettings> {
  DemoSettingsCubit()
      : super(const DemoSettings(
    preprocess: bool.fromEnvironment('PREPROCESS'),
    swapSize: bool.fromEnvironment('SWAP_SIZE'),
  ));

  void setPreprocess(bool v) => emit(state.copyWith(preprocess: v));
  void setSwapSize(bool v) => emit(state.copyWith(swapSize: v));
  void setShowBoxes(bool v) => emit(state.copyWith(showBoxes: v));
  void setAllowServerFallback(bool v) =>
      emit(state.copyWith(allowServerFallback: v));
}