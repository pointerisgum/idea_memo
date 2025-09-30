import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ideamemo/presentation/viewmodels/auth_viewmodel.dart';
import 'package:ideamemo/presentation/viewmodels/font_size_viewmodel.dart';
import 'package:ideamemo/core/constants/app_colors.dart';
import 'package:ideamemo/core/utils/font_size_manager.dart';
import 'package:ideamemo/core/utils/dialog_utils.dart';
import 'package:ideamemo/core/services/dev_data_service.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authNotifier = ref.read(authViewModelProvider.notifier);
    // 글씨 크기 변경을 실시간으로 반영하기 위해 watch
    ref.watch(fontSizeNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(CupertinoIcons.back, color: AppColors.textOnPrimary),
            onPressed: () => context.pop(),
          ),
        ),
        title: Text(
          '설정',
          style: TextStyle(
            color: AppColors.textOnPrimary,
            fontSize: AppFontSizes.headlineTextSize,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // 데이터 리셋 버튼 (디버그 모드에서만 표시)
              if (kDebugMode) ...[
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.lightShadow,
                        offset: const Offset(0, 4),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _resetIdeasData(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Colors.red,
                                    Colors.orange
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                CupertinoIcons.refresh_bold,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                '아이디어 데이터 리셋 (DEV)',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: AppFontSizes.settingsItemSize,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 글씨 크기 설정 버튼
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.lightShadow,
                      offset: const Offset(0, 4),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      context.push('/font-size-settings');
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              CupertinoIcons.textformat_size,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              '글씨 크기',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: AppFontSizes.settingsItemSize,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 로그아웃 버튼
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.lightShadow,
                      offset: const Offset(0, 4),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () async {
                      final confirmed = await DialogUtils.showLogoutConfirmation(
                        context: context,
                      );
                      if (confirmed) {
                        await authNotifier.signOut();
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              CupertinoIcons.square_arrow_right,
                              color: Colors.red,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              '로그아웃',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: AppFontSizes.settingsItemSize,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 계정 탈퇴 버튼
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.lightShadow,
                      offset: const Offset(0, 4),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () async {
                      debugPrint('🔄 [SETTINGS] 탈퇴 버튼 클릭');

                      // 1차 확인
                      final firstConfirmed = await DialogUtils.showDeleteConfirmation(context: context);
                      debugPrint('🔄 [SETTINGS] 1차 확인 결과: $firstConfirmed');

                      if (!firstConfirmed) return;

                      // 2차 최종 확인
                      final finalConfirmed = await DialogUtils.showFinalDeleteConfirmation(context: context);
                      debugPrint('🔄 [SETTINGS] 최종 확인 결과: $finalConfirmed');

                      if (finalConfirmed) {
                        debugPrint('🔄 [SETTINGS] 계정 삭제 시작');
                        try {
                          await authNotifier.deleteAccount();
                          // 성공 시 즉시 로그인 화면으로 이동
                          if (context.mounted) {
                            context.go('/login');
                          }
                        } catch (e) {
                          if (context.mounted) {
                            String errorMessage = '계정 탈퇴 중 오류가 발생했습니다.\n다시 시도해주세요.';

                            // 에러 타입별 메시지 커스터마이징 (새로운 서비스 기반)
                            final errorString = e.toString();
                            if (errorString.contains('재인증이 취소')) {
                              errorMessage = '재인증이 취소되었습니다.\n계정 탈퇴를 위해서는 재인증이 필요합니다.';
                            } else if (errorString.contains('네트워크 연결')) {
                              errorMessage = '네트워크 연결을 확인하고\n다시 시도해주세요.';
                            } else if (errorString.contains('앱을 재시작')) {
                              errorMessage = 'Google 인증에 문제가 발생했습니다.\n\n해결 방법:\n• 앱을 완전히 종료 후 재시작\n• 다시 시도해주세요';
                            } else if (errorString.contains('카카오 계정으로 다시 로그인')) {
                              errorMessage = '카카오 계정 확인에 실패했습니다.\n\n카카오 계정으로 다시 로그인 후\n시도해주세요.';
                            } else if (errorString.contains('Apple') || errorString.contains('지원되지 않는')) {
                              errorMessage = '현재 로그인 방식으로는\n계정 탈퇴가 지원되지 않습니다.\n\n고객센터로 문의해주세요.';
                            }

                            await DialogUtils.showError(
                              context: context,
                              title: '탈퇴 실패',
                              message: errorMessage,
                            );
                          }
                        }
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              CupertinoIcons.delete,
                              color: Colors.red,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              '계정 탈퇴',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: AppFontSizes.settingsItemSize,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  /// 아이디어 데이터 리셋 (디버그 모드 전용)
  void _resetIdeasData(BuildContext context) async {
    try {
      // 확인 다이얼로그
      final confirmed = await DialogUtils.showConfirmation(
        context: context,
        title: '데이터 리셋 (개발용)',
        message: '모든 아이디어 데이터를 삭제하고\n새로운 샘플 데이터로 교체하시겠습니까?',
        okLabel: '리셋',
        cancelLabel: '취소',
      );

      if (!confirmed) return;

      // 로딩 다이얼로그 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // DevDataService를 통한 데이터 리셋
      await DevDataService.resetIdeasData();

      // 로딩 다이얼로그 닫기
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // 성공 메시지
      if (context.mounted) {
        await DialogUtils.showInfo(
          context: context,
          title: '완료',
          message: '아이디어 데이터가 성공적으로 리셋되었습니다!\n\n10개의 샘플 아이디어가 추가되었습니다.',
        );
      }
    } catch (e) {
      // 로딩 다이얼로그 닫기
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // 에러 메시지
      if (context.mounted) {
        await DialogUtils.showError(
          context: context,
          title: '오류',
          message: '데이터 리셋 중 오류가 발생했습니다:\n$e',
        );
      }
    }
  }
}
