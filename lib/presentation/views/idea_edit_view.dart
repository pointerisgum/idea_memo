import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ideamemo/core/constants/app_colors.dart';
import 'package:ideamemo/core/utils/font_size_manager.dart';
import 'package:ideamemo/core/services/firestore_service.dart';
import 'package:ideamemo/core/utils/dialog_utils.dart';
import 'package:ideamemo/domain/entities/idea.dart';
import 'package:ideamemo/presentation/viewmodels/font_size_viewmodel.dart';
import 'package:ideamemo/presentation/viewmodels/idea_viewmodel.dart';

class IdeaEditView extends ConsumerStatefulWidget {
  final String ideaId;

  const IdeaEditView({
    super.key,
    required this.ideaId,
  });

  @override
  ConsumerState<IdeaEditView> createState() => _IdeaEditViewState();
}

class _IdeaEditViewState extends ConsumerState<IdeaEditView> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _titleFocusNode = FocusNode();
  final _contentFocusNode = FocusNode();

  Idea? _originalIdea;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadIdea();

    // 텍스트 변경 감지
    _titleController.addListener(_onTextChanged);
    _contentController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (_originalIdea != null) {
      final hasChanges = _titleController.text != _originalIdea!.title || _contentController.text != _originalIdea!.content;

      if (hasChanges != _hasChanges) {
        setState(() {
          _hasChanges = hasChanges;
        });
      }
    }
  }

  Future<void> _loadIdea() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final idea = await FirestoreService.getIdea(widget.ideaId);

      if (mounted && idea != null) {
        setState(() {
          _originalIdea = idea;
          _titleController.text = idea.title;
          _contentController.text = idea.content;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '아이디어를 불러오는데 실패했습니다: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveIdea() async {
    if (_titleController.text.trim().isEmpty) {
      DialogUtils.showInfo(
        context: context,
        title: '알림',
        message: '제목을 입력해주세요.',
      );
      return;
    }

    try {
      setState(() {
        _isSaving = true;
      });

      final updatedIdea = _originalIdea!.copyWith(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        updatedAt: DateTime.now(),
        // 기존 고정/북마크 상태 유지
        isPinned: _originalIdea!.isPinned,
        pinnedAt: _originalIdea!.pinnedAt,
        isBookmarked: _originalIdea!.isBookmarked,
        bookmarkedAt: _originalIdea!.bookmarkedAt,
      );

      await FirestoreService.updateIdea(updatedIdea);

      if (mounted) {
        // 메인 페이지의 아이디어 목록 새로고침
        ref.read(ideaViewModelNotifierProvider.notifier).loadIdeas();

        // 저장 완료 후 상세 페이지로 돌아가기
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        DialogUtils.showError(
          context: context,
          title: '저장 실패',
          message: '아이디어 저장에 실패했습니다: $e',
        );
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) {
      return true;
    }

    final shouldDiscard = await DialogUtils.showConfirmation(
      context: context,
      title: '변경사항 저장',
      message: '변경된 내용이 있습니다. 저장하지 않고 나가시겠습니까?',
      okLabel: '나가기',
      cancelLabel: '취소',
      isDestructiveAction: true,
    );

    return shouldDiscard;
  }

  @override
  Widget build(BuildContext context) {
    // 글씨 크기 변경을 실시간으로 반영하기 위해 watch
    ref.watch(fontSizeNotifierProvider);

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && _hasChanges) {
          final shouldPop = await _onWillPop();
          if (shouldPop && mounted) {
            context.pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              CupertinoIcons.xmark,
              color: AppColors.textPrimary,
              size: 24,
            ),
            onPressed: () async {
              if (_hasChanges) {
                final shouldDiscard = await _onWillPop();
                if (shouldDiscard && mounted) {
                  context.pop();
                }
              } else {
                context.pop();
              }
            },
          ),
          title: Text(
            '아이디어 수정',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: AppFontSizes.headlineTextSize,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            if (_isSaving)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              )
            else
              TextButton(
                onPressed: _hasChanges ? _saveIdea : null,
                child: Text(
                  '저장',
                  style: TextStyle(
                    color: _hasChanges ? AppColors.primary : AppColors.textSecondary,
                    fontSize: AppFontSizes.buttonTextSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: AppFontSizes.bodyTextSize,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadIdea,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                '다시 시도',
                style: TextStyle(
                  fontSize: AppFontSizes.buttonTextSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목 입력
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
                  offset: const Offset(0, 2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '제목',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: AppFontSizes.captionTextSize,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    focusNode: _titleFocusNode,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: AppFontSizes.ideaTitleSize,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: '제목을 입력하세요',
                      hintStyle: TextStyle(
                        color: AppColors.textHint,
                        fontSize: AppFontSizes.ideaTitleSize,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) {
                      _contentFocusNode.requestFocus();
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 내용 입력
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
                  offset: const Offset(0, 2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '내용',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: AppFontSizes.captionTextSize,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _contentController,
                    focusNode: _contentFocusNode,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: AppFontSizes.ideaContentSize,
                      height: 1.5,
                    ),
                    decoration: InputDecoration(
                      hintText: '내용을 입력하세요',
                      hintStyle: TextStyle(
                        color: AppColors.textHint,
                        fontSize: AppFontSizes.ideaContentSize,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    maxLines: null,
                    minLines: 5,
                    textInputAction: TextInputAction.done,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
