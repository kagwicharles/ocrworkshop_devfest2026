import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DemoSettings extends Equatable {
  const DemoSettings({
    this.preprocess = false,
    this.swapSize = false,
    this.showBoxes = true,
  });

  /// Grayscale + contrast before OCR (the "made it worse" experiment).
  final bool preprocess;

  /// Swaps image width/height in the overlay: shows the coordinate bug.
  final bool swapSize;

  /// Draw the recognized boxes over the photo.
  final bool showBoxes;

  DemoSettings copyWith({bool? preprocess, bool? swapSize, bool? showBoxes}) =>
      DemoSettings(
        preprocess: preprocess ?? this.preprocess,
        swapSize: swapSize ?? this.swapSize,
        showBoxes: showBoxes ?? this.showBoxes,
      );

  @override
  List<Object?> get props => [preprocess, swapSize, showBoxes];
}

/// Runtime switches for the live demo. The --dart-define flags still work
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
}