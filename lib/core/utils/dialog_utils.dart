import 'package:flutter/material.dart';
import 'package:ideamemo/core/constants/app_colors.dart';
import 'package:ideamemo/core/utils/font_size_manager.dart';

/// 통일된 커스텀 다이얼로그 유틸리티 클래스
/// 모든 플랫폼에서 동일한 아름다운 다이얼로그 디자인 제공
class DialogUtils {
  /// 기본 확인 다이얼로그
  static Future<void> showInfo({
    required BuildContext context,
    required String title,
    required String message,
    String? okLabel,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 10,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.surface,
                AppColors.surface.withOpacity(0.8),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 아이콘
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.info_outline,
                  color: AppColors.primary,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              // 제목
              Text(
                title,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: AppFontSizes.dialogTitleSize,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              // 메시지
              Text(
                message,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: AppFontSizes.dialogContentSize,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    okLabel ?? '확인',
                    style: TextStyle(
                      fontSize: AppFontSizes.dialogButtonSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 성공 다이얼로그
  static Future<void> showSuccess({
    required BuildContext context,
    required String title,
    required String message,
    String? okLabel,
  }) async {
    await _showStyledDialog(
      context: context,
      title: title,
      message: message,
      okLabel: okLabel,
      icon: Icons.check_circle_outline,
      iconColor: Colors.green,
    );
  }

  /// 에러 다이얼로그
  static Future<void> showError({
    required BuildContext context,
    required String title,
    required String message,
    String? okLabel,
  }) async {
    await _showStyledDialog(
      context: context,
      title: title,
      message: message,
      okLabel: okLabel,
      icon: Icons.error_outline,
      iconColor: Colors.red,
    );
  }

  /// 스타일된 다이얼로그 (내부 메서드)
  static Future<void> _showStyledDialog({
    required BuildContext context,
    required String title,
    required String message,
    String? okLabel,
    required IconData icon,
    required Color iconColor,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 10,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.surface,
                AppColors.surface.withOpacity(0.8),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 아이콘
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              // 제목
              Text(
                title,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: AppFontSizes.dialogTitleSize,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              // 메시지
              Text(
                message,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: AppFontSizes.dialogContentSize,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: iconColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    okLabel ?? '확인',
                    style: TextStyle(
                      fontSize: AppFontSizes.dialogButtonSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 확인/취소 다이얼로그
  static Future<bool> showConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    String? okLabel,
    String? cancelLabel,
    bool isDestructiveAction = false,
  }) async {
    bool? result;

    // 모든 플랫폼에서 동일한 커스텀 다이얼로그 사용
    result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 10,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.surface,
                AppColors.surface.withOpacity(0.8),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 아이콘
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isDestructiveAction ? Colors.red.withOpacity(0.1) : AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDestructiveAction ? Icons.warning_outlined : Icons.help_outline,
                  color: isDestructiveAction ? Colors.red : AppColors.primary,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              // 제목
              Text(
                title,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: AppFontSizes.dialogTitleSize,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              // 메시지
              Text(
                message,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: AppFontSizes.dialogContentSize,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // 버튼들
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: BorderSide(color: AppColors.textSecondary.withOpacity(0.3)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        cancelLabel ?? '취소',
                        style: TextStyle(
                          fontSize: AppFontSizes.dialogButtonSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDestructiveAction ? Colors.red : AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        okLabel ?? '확인',
                        style: TextStyle(
                          fontSize: AppFontSizes.dialogButtonSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    return result ?? false;
  }

  /// 로그아웃 확인 다이얼로그
  static Future<bool> showLogoutConfirmation({
    required BuildContext context,
  }) async {
    return await showConfirmation(
      context: context,
      title: '로그아웃',
      message: '정말 로그아웃하시겠습니까?',
      okLabel: '로그아웃',
      cancelLabel: '취소',
      isDestructiveAction: true,
    );
  }

  /// 탈퇴 다이얼로그 (1차 확인)
  static Future<bool> showDeleteConfirmation({
    required BuildContext context,
    String? customMessage,
  }) async {
    return await showConfirmation(
      context: context,
      title: '계정 탈퇴',
      message: '계정을 탈퇴하시겠습니까?\n\n탈퇴 시 모든 데이터가 삭제되며,\n복구할 수 없습니다.',
      okLabel: '탈퇴',
      cancelLabel: '취소',
      isDestructiveAction: true,
    );
  }

  /// 계정 삭제 최종 확인 다이얼로그 (2차 확인)
  static Future<bool> showFinalDeleteConfirmation({
    required BuildContext context,
  }) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 10,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.surface,
                    AppColors.surface.withOpacity(0.8),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 경고 아이콘
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_outlined,
                      color: Colors.red,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 제목
                  Text(
                    '최종 확인',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: AppFontSizes.dialogTitleSize,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  // 메시지
                  Text(
                    '이 작업은 되돌릴 수 없습니다!\n\n• 모든 아이디어 메모가 삭제됩니다\n• 계정 정보가 완전히 삭제됩니다\n• 복구가 불가능합니다\n\n정말로 계속하시겠습니까?',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: AppFontSizes.dialogContentSize,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  // 버튼들
                  Row(
                    children: [
                      // 취소 버튼
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            side: BorderSide(color: AppColors.textSecondary.withOpacity(0.3)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            '취소',
                            style: TextStyle(
                              fontSize: AppFontSizes.dialogButtonSize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // 최종 탈퇴 버튼
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            '네, 탈퇴합니다',
                            style: TextStyle(
                              fontSize: AppFontSizes.dialogButtonSize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ) ??
        false;
  }

  /// 선택 다이얼로그 (ActionSheet 스타일)
  static Future<T?> showSelection<T>({
    required BuildContext context,
    required String title,
    String? message,
    required List<DialogAction<T>> actions,
    String? cancelLabel,
  }) async {
    return await showModalBottomSheet<T>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 제목 영역
            Column(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: AppFontSizes.dialogTitleSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (message != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: AppFontSizes.dialogContentSize,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
            // 액션 버튼들
            ...actions.map((action) => Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(action.value),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: action.isDestructive ? Colors.red : AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      action.label,
                      style: TextStyle(
                        fontSize: AppFontSizes.dialogButtonSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )),
            // 취소 버튼
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 8),
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: BorderSide(color: AppColors.textSecondary.withOpacity(0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  cancelLabel ?? '취소',
                  style: TextStyle(
                    fontSize: AppFontSizes.dialogButtonSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 텍스트 입력 다이얼로그
  static Future<String?> showTextInput({
    required BuildContext context,
    required String title,
    String? message,
    String? hintText,
    String? initialText,
    String? okLabel,
    String? cancelLabel,
  }) async {
    final controller = TextEditingController(text: initialText);
    String? result;

    result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 10,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.surface,
                AppColors.surface.withOpacity(0.8),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 아이콘
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.edit_outlined,
                  color: AppColors.primary,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              // 제목
              Text(
                title,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: AppFontSizes.dialogTitleSize,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(
                  message,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: AppFontSizes.dialogContentSize,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 20),
              // 텍스트 입력 필드
              TextField(
                controller: controller,
                autofocus: true,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: AppFontSizes.dialogButtonSize,
                ),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: TextStyle(
                    color: AppColors.textSecondary.withOpacity(0.6),
                    fontSize: AppFontSizes.dialogButtonSize,
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // 버튼들
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: BorderSide(color: AppColors.textSecondary.withOpacity(0.3)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        cancelLabel ?? '취소',
                        style: TextStyle(
                          fontSize: AppFontSizes.dialogButtonSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(controller.text),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        okLabel ?? '확인',
                        style: TextStyle(
                          fontSize: AppFontSizes.dialogButtonSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    controller.dispose();
    return result;
  }

  /// 앱 종료 확인 다이얼로그
  static Future<bool> showExitConfirmation({
    required BuildContext context,
  }) async {
    return await showConfirmation(
      context: context,
      title: '앱 종료',
      message: '앱을 종료하시겠습니까?',
      okLabel: '종료',
      cancelLabel: '취소',
      isDestructiveAction: true,
    );
  }

  /// 저장하지 않고 나가기 확인 다이얼로그
  static Future<bool> showUnsavedChangesConfirmation({
    required BuildContext context,
  }) async {
    return await showConfirmation(
      context: context,
      title: '저장하지 않고 나가시겠습니까?',
      message: '변경사항이 저장되지 않습니다.',
      okLabel: '나가기',
      cancelLabel: '취소',
      isDestructiveAction: true,
    );
  }

  /// 네트워크 에러 다이얼로그
  static Future<void> showNetworkError({
    required BuildContext context,
    String? customMessage,
  }) async {
    await showError(
      context: context,
      title: '네트워크 오류',
      message: customMessage ?? '인터넷 연결을 확인하고 다시 시도해주세요.',
    );
  }

  /// 권한 요청 다이얼로그
  static Future<bool> showPermissionRequest({
    required BuildContext context,
    required String permissionName,
    required String reason,
  }) async {
    return await showConfirmation(
      context: context,
      title: '$permissionName 권한 필요',
      message: reason,
      okLabel: '설정으로 이동',
      cancelLabel: '취소',
    );
  }
}

/// 다이얼로그 액션 클래스
class DialogAction<T> {
  final String label;
  final T value;
  final bool isDestructive;

  const DialogAction({
    required this.label,
    required this.value,
    this.isDestructive = false,
  });
}
