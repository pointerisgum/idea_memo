import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ideamemo/core/constants/app_colors.dart';
import 'package:ideamemo/core/utils/font_size_manager.dart';
import 'package:ideamemo/presentation/viewmodels/font_size_viewmodel.dart';

class FontSizeSettingsView extends ConsumerStatefulWidget {
  const FontSizeSettingsView({super.key});

  @override
  ConsumerState<FontSizeSettingsView> createState() => _FontSizeSettingsViewState();
}

class _FontSizeSettingsViewState extends ConsumerState<FontSizeSettingsView> {
  @override
  void initState() {
    super.initState();
    // 글씨 크기 설정 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fontSizeNotifierProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final fontSizeState = ref.watch(fontSizeNotifierProvider);
    final fontSizeNotifier = ref.read(fontSizeNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            CupertinoIcons.back,
            color: AppColors.textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          '글씨 크기',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 미리보기 섹션
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 미리보기 라벨
                    Text(
                      '미리보기',
                      style: TextStyle(
                        fontSize: AppFontSizes.captionTextSize,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 아이디어 제목 미리보기
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 20,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '새로운 아이디어 제목',
                            style: TextStyle(
                              fontSize: AppFontSizes.ideaTitleSize,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // 아이디어 내용 미리보기
                    Text(
                      '아이디어의 상세 내용이 이렇게 표시됩니다. 글씨 크기를 조절해서 가장 편안한 크기로 설정해보세요.',
                      style: TextStyle(
                        fontSize: AppFontSizes.ideaContentSize,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 12),

                    // 날짜 미리보기
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '24.12.25 14:30',
                        style: TextStyle(
                          fontSize: AppFontSizes.ideaDateSize,
                          color: AppColors.textHint,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // 글씨 크기 조절 섹션
              Text(
                '글씨 크기 조절',
                style: TextStyle(
                  fontSize: AppFontSizes.titleTextSize,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 16),

              // 슬라이더
              Container(
                padding: const EdgeInsets.all(20),
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
                child: Column(
                  children: [
                    // 슬라이더
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppColors.primary,
                        inactiveTrackColor: AppColors.primary.withOpacity(0.2),
                        thumbColor: AppColors.primary,
                        overlayColor: AppColors.primary.withOpacity(0.2),
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                      ),
                      child: Slider(
                        value: fontSizeNotifier.currentSliderValue,
                        onChanged: (value) {
                          fontSizeNotifier.changeFontSizeBySlider(value);
                        },
                        divisions: 2,
                        min: 0.0,
                        max: 1.0,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 크기 라벨들
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: FontSizeType.values.map((type) {
                        final isSelected = fontSizeState.currentFontSize == type;
                        return Text(
                          type.displayName,
                          style: TextStyle(
                            fontSize: AppFontSizes.captionTextSize,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? AppColors.primary : AppColors.textSecondary,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 현재 설정 표시
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.info_circle_fill,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '현재 설정: ${fontSizeState.currentFontSize.displayName}',
                      style: TextStyle(
                        fontSize: AppFontSizes.bodyTextSize,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // 안내 텍스트
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '💡 글씨 크기 변경은 앱 전체에 적용되며, 설정이 자동으로 저장됩니다.',
                  style: TextStyle(
                    fontSize: AppFontSizes.captionTextSize,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
