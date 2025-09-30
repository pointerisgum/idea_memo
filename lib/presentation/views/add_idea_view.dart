import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ideamemo/presentation/viewmodels/idea_viewmodel.dart';
import 'package:ideamemo/presentation/viewmodels/font_size_viewmodel.dart';
import 'package:ideamemo/core/constants/app_colors.dart';
import 'package:ideamemo/core/utils/font_size_manager.dart';
import 'package:ideamemo/core/utils/snackbar_utils.dart';

class AddIdeaView extends ConsumerStatefulWidget {
  const AddIdeaView({super.key});

  @override
  ConsumerState<AddIdeaView> createState() => _AddIdeaViewState();
}

class _AddIdeaViewState extends ConsumerState<AddIdeaView> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _contentFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // 화면 진입 시 제목 입력란에 포커스
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _titleFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  void _saveIdea() {
    HapticFeedback.lightImpact();

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty) {
      SnackbarUtils.showError(context, '제목을 입력해주세요.');
      return;
    }

    if (content.isEmpty) {
      SnackbarUtils.showError(context, '내용을 입력해주세요.');
      return;
    }

    ref.read(ideaViewModelNotifierProvider.notifier).addIdea(
          title: title,
          content: content,
        );

    // SnackbarUtils.showSuccess(context, '아이디어가 성공적으로 저장되었습니다!');

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
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
          '새 아이디어',
          style: TextStyle(
            color: AppColors.textOnPrimary,
            fontSize: AppFontSizes.titleTextSize,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton(
              onPressed: _saveIdea,
              child: Text(
                '저장',
                style: TextStyle(
                  color: AppColors.textOnPrimary,
                  fontSize: AppFontSizes.captionTextSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목 입력 필드
              Container(
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
                child: TextField(
                  controller: _titleController,
                  focusNode: _titleFocusNode,
                  style: TextStyle(
                    fontSize: AppFontSizes.inputTextSize,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: '제목을 입력하세요',
                    hintStyle: TextStyle(
                      color: AppColors.textHint,
                      fontSize: AppFontSizes.inputTextSize,
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(20),
                  ),
                  maxLines: 1,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) {
                    _contentFocusNode.requestFocus();
                  },
                ),
              ),

              const SizedBox(height: 20),

              // 내용 입력 필드
              Expanded(
                child: Container(
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
                  child: TextField(
                    controller: _contentController,
                    focusNode: _contentFocusNode,
                    style: TextStyle(
                      fontSize: AppFontSizes.bodyTextSize,
                      height: 1.6,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: '아이디어의 내용을 자유롭게 적어보세요',
                      hintStyle: TextStyle(
                        color: AppColors.textHint,
                        fontSize: AppFontSizes.bodyTextSize,
                        height: 1.6,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(20),
                    ),
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 하단 버튼 영역
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.grey300,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: OutlinedButton(
                        onPressed: () => context.pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          minimumSize: const Size.fromHeight(56),
                        ),
                        child: Text(
                          '취소',
                          style: TextStyle(
                            fontSize: AppFontSizes.buttonTextSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            offset: const Offset(0, 8),
                            blurRadius: 24,
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _saveIdea,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: AppColors.textOnPrimary,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          minimumSize: const Size.fromHeight(56),
                        ),
                        child: Text(
                          '저장하기',
                          style: TextStyle(
                            fontSize: AppFontSizes.buttonTextSize,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
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
  }
}
