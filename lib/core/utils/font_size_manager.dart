import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// 글씨 크기 설정 타입
enum FontSizeType {
  small('작게', 1.0), // 현재 크기 기준 (기본값)
  medium('보통', 1.111), // 약 11% 증가
  large('크게', 1.222); // 약 22% 증가

  const FontSizeType(this.displayName, this.scale);
  final String displayName;
  final double scale;
}

/// 글씨 크기 관리 클래스
class FontSizeManager {
  static const String _fontSizeKey = 'font_size_setting';
  static FontSizeType _currentFontSize = FontSizeType.medium; // 기본값은 보통

  /// 현재 글씨 크기 타입
  static FontSizeType get currentFontSize => _currentFontSize;

  /// 현재 스케일 값
  static double get currentScale => _currentFontSize.scale;

  /// SharedPreferences에서 설정 로드
  static Future<void> loadFontSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedIndex = prefs.getInt(_fontSizeKey) ?? 1; // 기본값: 보통(1)

      if (savedIndex >= 0 && savedIndex < FontSizeType.values.length) {
        _currentFontSize = FontSizeType.values[savedIndex];
      } else {
        _currentFontSize = FontSizeType.medium;
      }

      debugPrint('✅ [FONT] 글씨 크기 로드: ${_currentFontSize.displayName} (${_currentFontSize.scale}x)');
    } catch (e) {
      debugPrint('❌ [FONT] 글씨 크기 로드 실패: $e');
      _currentFontSize = FontSizeType.medium;
    }
  }

  /// SharedPreferences에 설정 저장
  static Future<void> saveFontSize(FontSizeType fontSizeType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_fontSizeKey, fontSizeType.index);
      _currentFontSize = fontSizeType;

      debugPrint('✅ [FONT] 글씨 크기 저장: ${fontSizeType.displayName} (${fontSizeType.scale}x)');
    } catch (e) {
      debugPrint('❌ [FONT] 글씨 크기 저장 실패: $e');
    }
  }

  /// 기본 크기에 현재 스케일을 적용한 크기 반환
  static double getScaledSize(double baseSize) {
    return baseSize * currentScale;
  }
}

/// 글씨 크기 상수 클래스 (기존 하드코딩된 크기들을 여기서 관리)
class AppFontSizes {
  // 아이디어 관련
  static double get ideaTitleSize => FontSizeManager.getScaledSize(16);
  static double get ideaContentSize => FontSizeManager.getScaledSize(14);
  static double get ideaDateSize => FontSizeManager.getScaledSize(12);

  // 버튼 관련
  static double get buttonTextSize => FontSizeManager.getScaledSize(14);
  static double get buttonLargeTextSize => FontSizeManager.getScaledSize(16);

  // 일반 텍스트
  static double get bodyTextSize => FontSizeManager.getScaledSize(14);
  static double get captionTextSize => FontSizeManager.getScaledSize(12);
  static double get headlineTextSize => FontSizeManager.getScaledSize(18);
  static double get titleTextSize => FontSizeManager.getScaledSize(16);

  // 입력 필드
  static double get inputTextSize => FontSizeManager.getScaledSize(15);
  static double get inputLabelSize => FontSizeManager.getScaledSize(12);

  // 다이얼로그
  static double get dialogTitleSize => FontSizeManager.getScaledSize(17);
  static double get dialogContentSize => FontSizeManager.getScaledSize(13);
  static double get dialogButtonSize => FontSizeManager.getScaledSize(14);

  // 시계 위젯
  static double get clockDateSize => FontSizeManager.getScaledSize(14);
  static double get clockTimeSize => FontSizeManager.getScaledSize(24);

  // 설정 화면
  static double get settingsItemSize => FontSizeManager.getScaledSize(16);
  static double get settingsDescSize => FontSizeManager.getScaledSize(12);
}
