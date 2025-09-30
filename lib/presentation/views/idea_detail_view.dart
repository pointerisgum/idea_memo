import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ideamemo/core/constants/app_colors.dart';
import 'package:ideamemo/core/utils/font_size_manager.dart';
import 'package:ideamemo/core/services/firestore_service.dart';
import 'package:ideamemo/domain/entities/idea.dart';
import 'package:ideamemo/presentation/viewmodels/font_size_viewmodel.dart';

class IdeaDetailView extends ConsumerStatefulWidget {
  final String ideaId;

  const IdeaDetailView({
    super.key,
    required this.ideaId,
  });

  @override
  ConsumerState<IdeaDetailView> createState() => _IdeaDetailViewState();
}

class _IdeaDetailViewState extends ConsumerState<IdeaDetailView> {
  Idea? _idea;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadIdea();
  }

  Future<void> _loadIdea() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final idea = await FirestoreService.getIdea(widget.ideaId);

      if (mounted) {
        setState(() {
          _idea = idea;
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

  @override
  Widget build(BuildContext context) {
    // 글씨 크기 변경을 실시간으로 반영하기 위해 watch
    ref.watch(fontSizeNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            CupertinoIcons.back,
            color: AppColors.textPrimary,
            size: 24,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          '아이디어 상세',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: AppFontSizes.headlineTextSize,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await context.push('/idea-edit/${widget.ideaId}');
              // 수정 페이지에서 돌아온 후 데이터 새로고침
              _loadIdea();
            },
            child: Text(
              '수정',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: AppFontSizes.buttonTextSize,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: _buildBody(),
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

    if (_idea == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.doc_text,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              '아이디어를 찾을 수 없습니다',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: AppFontSizes.bodyTextSize,
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
          // 제목
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 제목 라벨과 생성일을 같은 줄에 표시
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '제목',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: AppFontSizes.captionTextSize,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    // 메인 화면과 동일한 날짜 스타일 (고정 여부 무관하게 동일)
                    // Container(
                    //   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    //   decoration: BoxDecoration(
                    //     color: AppColors.grey100,
                    //     borderRadius: BorderRadius.circular(8),
                    //   ),
                    //   child: Text(
                    //     DateFormat('yy.MM.dd HH:mm').format(_idea!.createdAt),
                    //     style: TextStyle(
                    //       fontSize: AppFontSizes.ideaDateSize,
                    //       color: AppColors.textHint,
                    //       fontWeight: FontWeight.w500,
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _idea!.title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: AppFontSizes.ideaTitleSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 내용
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
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
                Text(
                  _idea!.content,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: AppFontSizes.ideaContentSize,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
