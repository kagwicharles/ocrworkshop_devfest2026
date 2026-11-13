import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DemoSettings extends Equatable {
  const DemoSettings({
    this.preprocess = false,
    this.swapSize = false,
    this.showBoxes = true,
  });

  final bool preprocess;

  final bool swapSize;

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