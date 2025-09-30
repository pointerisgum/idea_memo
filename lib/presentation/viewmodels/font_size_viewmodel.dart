import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ideamemo/core/utils/font_size_manager.dart';
import 'package:flutter/foundation.dart';

part 'font_size_viewmodel.g.dart';
part 'font_size_viewmodel.freezed.dart';

@freezed
class FontSizeState with _$FontSizeState {
  const factory FontSizeState({
    @Default(FontSizeType.medium) FontSizeType currentFontSize,
    @Default(false) bool isLoading,
  }) = _FontSizeState;
}

@riverpod
class FontSizeNotifier extends _$FontSizeNotifier {
  @override
  FontSizeState build() {
    // 초기 상태는 FontSizeManager의 현재 설정을 반영
    return FontSizeState(
      currentFontSize: FontSizeManager.currentFontSize,
    );
  }

  /// 글씨 크기 초기화 (앱 시작 시 호출)
  Future<void> initialize() async {
    state = state.copyWith(isLoading: true);

    try {
      await FontSizeManager.loadFontSize();
      state = state.copyWith(
        currentFontSize: FontSizeManager.currentFontSize,
        isLoading: false,
      );

      debugPrint('✅ [FONT_VM] 글씨 크기 초기화 완료: ${state.currentFontSize.displayName}');
    } catch (e) {
      debugPrint('❌ [FONT_VM] 글씨 크기 초기화 실패: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  /// 글씨 크기 변경
  Future<void> changeFontSize(FontSizeType newFontSize) async {
    if (state.currentFontSize == newFontSize) return;

    try {
      await FontSizeManager.saveFontSize(newFontSize);
      state = state.copyWith(currentFontSize: newFontSize);

      debugPrint('✅ [FONT_VM] 글씨 크기 변경: ${newFontSize.displayName}');
    } catch (e) {
      debugPrint('❌ [FONT_VM] 글씨 크기 변경 실패: $e');
    }
  }

  /// 슬라이더 값으로 글씨 크기 변경 (0.0 ~ 1.0)
  void changeFontSizeBySlider(double sliderValue) {
    FontSizeType newFontSize;

    if (sliderValue <= 0.33) {
      newFontSize = FontSizeType.small;
    } else if (sliderValue <= 0.66) {
      newFontSize = FontSizeType.medium;
    } else {
      newFontSize = FontSizeType.large;
    }

    changeFontSize(newFontSize);
  }

  /// 현재 글씨 크기를 슬라이더 값으로 변환 (0.0 ~ 1.0)
  double get currentSliderValue {
    switch (state.currentFontSize) {
      case FontSizeType.small:
        return 0.0;
      case FontSizeType.medium:
        return 0.5;
      case FontSizeType.large:
        return 1.0;
    }
  }
}
