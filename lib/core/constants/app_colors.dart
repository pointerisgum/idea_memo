import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // 모던 그라데이션 컬러 (보라-핑크-오렌지 계열)
  static const Color primary = Color(0xFF6C5CE7); // 모던 보라
  static const Color primaryLight = Color(0xFF8B7ED8); // 연한 보라
  static const Color secondary = Color(0xFFFF6B6B); // 코랄 핑크
  static const Color accent = Color(0xFFFFD93D); // 밝은 노랑

  // 그라데이션
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [
      Color(0xFF6C5CE7),
      Color(0xFF8B7ED8)
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [
      Color(0xFFFF6B6B),
      Color(0xFFFF8E8E)
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [
      Color(0xFFFFD93D),
      Color(0xFFFFE066)
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // 중성 컬러 (모던한 그레이 스케일)
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF2D3436);
  static const Color grey50 = Color(0xFFFAFBFC);
  static const Color grey100 = Color(0xFFF1F3F4);
  static const Color grey200 = Color(0xFFE8EAED);
  static const Color grey300 = Color(0xFFDADCE0);
  static const Color grey400 = Color(0xFFBDC1C6);
  static const Color grey500 = Color(0xFF9AA0A6);
  static const Color grey600 = Color(0xFF80868B);
  static const Color grey700 = Color(0xFF5F6368);
  static const Color grey800 = Color(0xFF3C4043);
  static const Color grey900 = Color(0xFF202124);

  // 상태별 컬러 (모던 버전)
  static const Color success = Color(0xFF00D68F); // 민트 그린
  static const Color error = Color(0xFFFF6B6B); // 소프트 레드
  static const Color warning = Color(0xFFFFB800); // 골든 옐로우
  static const Color info = Color(0xFF4ECDC4); // 터쿠아즈

  // 텍스트 컬러
  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textSecondary = Color(0xFF636E72);
  static const Color textHint = Color(0xFFB2BEC3);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // 배경 컬러
  static const Color background = Color(0xFFFDFCFF); // 약간의 보라 틴트
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF8F9FA);

  // 카드 그림자 컬러
  static const Color shadow = Color(0x1A6C5CE7); // 보라 틴트 그림자
  static const Color lightShadow = Color(0x0D6C5CE7);
}
