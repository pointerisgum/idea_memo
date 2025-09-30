import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:ideamemo/presentation/viewmodels/idea_viewmodel.dart';
import 'package:ideamemo/presentation/viewmodels/home_viewmodel.dart';
import 'package:ideamemo/presentation/viewmodels/auth_viewmodel.dart';
import 'package:ideamemo/presentation/viewmodels/font_size_viewmodel.dart';
import 'package:ideamemo/presentation/widgets/time_widget.dart';
import 'package:ideamemo/domain/entities/idea.dart';
import 'package:ideamemo/core/constants/app_colors.dart';
import 'package:ideamemo/core/utils/font_size_manager.dart';

class MainView extends ConsumerStatefulWidget {
  const MainView({super.key});

  @override
  ConsumerState<MainView> createState() => _MainViewState();
}

class _MainViewState extends ConsumerState<MainView> with WidgetsBindingObserver {
  bool _hasShownPermissionSheet = false;
  bool _isPermissionSheetShowing = false; // 현재 바텀시트가 표시 중인지 추적
  bool _hasLoadedIdeas = false; // 아이디어 로딩 상태 추적

  @override
  void initState() {
    super.initState();
    // 앱 생명주기 관찰자 등록
    WidgetsBinding.instance.addObserver(this);

    // 인증 상태 확인 후 아이디어 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndLoadIdeas();
    });
  }

  // 인증 상태 확인 후 아이디어 로드
  void _checkAuthAndLoadIdeas() async {
    final authState = ref.read(authViewModelProvider);
    if (authState.isLoggedIn && !_hasLoadedIdeas) {
      debugPrint('🔄 [MAIN] 인증 확인됨 - 아이디어 로드 시작');
      _hasLoadedIdeas = true;
      await ref.read(ideaViewModelNotifierProvider.notifier).loadIdeas();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      debugPrint('🔄 앱이 포그라운드로 복귀 - 권한 상태 체크');
      // 앱이 포그라운드로 돌아올 때 권한 상태 체크
      Future.delayed(const Duration(milliseconds: 500), () {
        _checkPermissionOnResume();
      });
    }
  }

  // 포그라운드 복귀 시 권한 체크
  void _checkPermissionOnResume() async {
    try {
      final hasPermission = await ref.read(homeViewModelProvider.notifier).checkOverlayPermission();

      debugPrint('🔍 포그라운드 복귀 시 권한 상태: $hasPermission');

      if (hasPermission) {
        // 권한이 있는데 바텀시트가 떠있으면 닫기
        if (_isPermissionSheetShowing) {
          debugPrint('✅ 권한 허용됨 - 바텀시트 닫기');
          Navigator.of(context).pop(); // 바텀시트 강제로 닫기
          _isPermissionSheetShowing = false;
          _hasShownPermissionSheet = false;
        }
      } else {
        // 잠금화면 상태 확인 - 잠금화면에서는 바텀시트 표시 안함
        final homeState = ref.read(homeViewModelProvider);
        if (homeState.isLockScreenMode) {
          debugPrint('🔒 잠금화면 상태 - 바텀시트 표시 안함');
          return;
        }

        // 권한이 없고 바텀시트가 표시되지 않았으면 표시
        if (!_isPermissionSheetShowing) {
          debugPrint('⚠️ 권한 없음 - 바텀시트 표시');
          _hasShownPermissionSheet = false; // 플래그 리셋해서 다시 표시 가능하게
          _showPermissionBottomSheet();
        }
      }
    } catch (e) {
      debugPrint('❌ 포그라운드 복귀 시 권한 체크 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ideaState = ref.watch(ideaViewModelNotifierProvider);
    // 글씨 크기 변경을 실시간으로 반영하기 위해 watch
    ref.watch(fontSizeNotifierProvider);

    // 인증 상태 변화 감지하여 아이디어 로드
    ref.listen(authViewModelProvider, (previous, next) {
      if (next.isLoggedIn && !_hasLoadedIdeas) {
        debugPrint('🔄 [MAIN] 인증 상태 변화 감지 - 아이디어 로드');
        _hasLoadedIdeas = true;
        Future.microtask(() {
          ref.read(ideaViewModelNotifierProvider.notifier).loadIdeas();
        });
      } else if (!next.isLoggedIn && _hasLoadedIdeas) {
        // 로그아웃 시 상태 리셋
        _hasLoadedIdeas = false;
      }
    });

    // HomeViewModel 상태를 올바르게 가져오기
    final homeState = ref.watch(homeViewModelProvider);
    final isLockScreen = homeState.isLockScreenMode;
    final needsPermissionSetup = homeState.needsPermissionSetup;

    // 권한이 필요하고 잠금화면이 아니고 바텀시트가 표시되지 않았을 때만 표시
    if (needsPermissionSetup && !isLockScreen && !_hasShownPermissionSheet && !_isPermissionSheetShowing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showPermissionBottomSheet();
        _hasShownPermissionSheet = true;
      });
    }

    // 권한이 해결되면 플래그 리셋
    if (!needsPermissionSetup && _hasShownPermissionSheet) {
      _hasShownPermissionSheet = false;
      _isPermissionSheetShowing = false;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 상단 영역 (높이: 80)
            _buildTopSection(),

            // 중간 영역 (리스트뷰)
            Expanded(
              child: _buildIdeaList(ref.read(ideaViewModelNotifierProvider.notifier).filteredIdeas, ideaState.isLoading, ideaState.error),
            ),

            // 하단 영역 (높이: 60)
            _buildBottomSection(isLockScreen),
          ],
        ),
      ),
    );
  }

  // 권한 요청 바텀시트 표시
  void _showPermissionBottomSheet() {
    // 이미 표시 중이면 중복 표시 방지
    if (_isPermissionSheetShowing) {
      debugPrint('🔍 바텀시트 이미 표시 중 - 중복 방지');
      return;
    }

    _isPermissionSheetShowing = true; // 표시 중 플래그 설정

    showModalBottomSheet(
      context: context,
      isDismissible: false, // 바깥 터치로 닫기 방지
      enableDrag: false, // 드래그로 닫기 방지
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WillPopScope(
        onWillPop: () async => false, // 백키로 닫기 방지
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 상단 텍스트
                Text(
                  '편리한 이용을 위해\n아래의 접근권한 허용이 필요합니다',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppFontSizes.titleTextSize,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                // const SizedBox(height: 8),
                // const Text(
                //   '아래의 접근권한 허용이 필요합니다',
                //   style: TextStyle(
                //     fontSize: 18,
                //     fontWeight: FontWeight.w600,
                //     color: AppColors.textPrimary,
                //   ),
                // ),
                const SizedBox(height: 32),

                // 권한 항목
                Row(
                  children: [
                    // 아이콘
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        CupertinoIcons.layers_alt_fill,
                        size: 24,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // 텍스트
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '다른 앱 위에 표시',
                                style: TextStyle(
                                  fontSize: AppFontSizes.bodyTextSize,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '(필수)',
                                style: TextStyle(
                                  fontSize: AppFontSizes.captionTextSize,
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '앱 서비스 실행',
                            style: TextStyle(
                              fontSize: AppFontSizes.captionTextSize,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // 동의 버튼
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _isPermissionSheetShowing = false; // 플래그 해제
                      Navigator.of(context).pop(); // 바텀시트 닫기
                      ref.read(homeViewModelProvider.notifier).requestOverlayPermission();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: AppColors.textOnPrimary,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      '동의',
                      style: TextStyle(
                        fontSize: AppFontSizes.buttonTextSize,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).then((_) {
      // 바텀시트가 닫힐 때 플래그 해제
      _isPermissionSheetShowing = false;
      debugPrint('🔍 바텀시트 닫힘 - 플래그 해제');
    });
  }

  Widget _buildTopSection() {
    return Container(
      height: 100,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            offset: const Offset(0, 8),
            blurRadius: 24,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Stack(
        children: [
          // 정렬 버튼을 왼쪽에 배치
          Positioned(
            left: 16,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _showSortBottomSheet();
                    },
                    child: const Icon(
                      CupertinoIcons.sort_down,
                      color: AppColors.textOnPrimary,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // TimeWidget을 정중앙에 배치
          Positioned.fill(
            child: Center(
              child: TimeWidget(
                showDate: true,
                dateStyle: TextStyle(
                  fontSize: AppFontSizes.clockDateSize,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textOnPrimary,
                  letterSpacing: 0.5,
                ),
                timeStyle: TextStyle(
                  fontSize: AppFontSizes.clockTimeSize,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textOnPrimary,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          // 설정 버튼을 오른쪽에 배치
          Positioned(
            right: 16,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(
                    CupertinoIcons.settings,
                    color: AppColors.textOnPrimary,
                    size: 20,
                  ),
                  onPressed: () {
                    context.push('/settings');
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdeaList(List<Idea> ideas, bool isLoading, String? error) {
    // 로딩 상태
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppColors.primary,
            ),
            SizedBox(height: 16),
            Text(
              '아이디어를 불러오는 중...',
              style: TextStyle(
                fontSize: AppFontSizes.bodyTextSize,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    // 에러 상태
    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                CupertinoIcons.exclamationmark_triangle_fill,
                size: 36,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '데이터를 불러올 수 없습니다',
              style: TextStyle(
                fontSize: AppFontSizes.titleTextSize,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                fontSize: AppFontSizes.captionTextSize,
                color: AppColors.textHint,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(ideaViewModelNotifierProvider.notifier).loadIdeas();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    // 빈 상태
    if (ideas.isEmpty) {
      final ideaState = ref.watch(ideaViewModelNotifierProvider);
      final isBookmarkFilterOn = ideaState.isBookmarkFilterOn;

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: isBookmarkFilterOn
                    ? LinearGradient(
                        colors: [
                          Colors.blue.shade400,
                          Colors.blue.shade600
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : AppColors.accentGradient,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: isBookmarkFilterOn ? Colors.blue.withOpacity(0.3) : AppColors.accent.withOpacity(0.3),
                    offset: const Offset(0, 8),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: Icon(
                isBookmarkFilterOn ? CupertinoIcons.bookmark_fill : CupertinoIcons.lightbulb_fill,
                size: 36,
                color: AppColors.textOnPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isBookmarkFilterOn ? '북마크한 아이디어가 없습니다' : '아직 아이디어가 없습니다',
              style: TextStyle(
                fontSize: AppFontSizes.titleTextSize,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isBookmarkFilterOn ? '' : '새로운 아이디어를 추가해보세요!',
              style: TextStyle(
                fontSize: AppFontSizes.bodyTextSize,
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      );
    }

    // 정상 상태 - 아이디어 목록
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: ideas.length,
      itemBuilder: (context, index) {
        final idea = ideas[index];
        return _buildDismissibleIdeaItem(idea);
      },
    );
  }

  Widget _buildDismissibleIdeaItem(Idea idea) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Slidable(
        key: Key(idea.id),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          extentRatio: 0.7, // 전체 너비의 60%를 액션 영역으로 사용 (240px 정도)
          children: [
            // 상단고정 버튼
            CustomSlidableAction(
              flex: 1, // 동일한 비율로 분할 (80px씩)
              onPressed: (context) async {
                debugPrint('🔄 상단고정 클릭: ${idea.title}');
                await ref.read(ideaViewModelNotifierProvider.notifier).togglePinIdea(idea.id, context);

                // 에러가 있으면 스낵바로 표시
                final error = ref.read(ideaViewModelNotifierProvider).error;
                if (error != null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(error),
                      backgroundColor: Colors.red,
                    ),
                  );
                  ref.read(ideaViewModelNotifierProvider.notifier).clearError();
                }
              },
              backgroundColor: idea.isPinned
                  ? Colors.orange.withOpacity(0.9) // 고정된 경우 진한 색
                  : Colors.orange.withOpacity(0.7), // 일반 상태
              child: Icon(
                idea.isPinned ? CupertinoIcons.pin_fill : CupertinoIcons.pin,
                color: Colors.white,
                size: 28,
              ),
            ),
            // 북마크 버튼
            CustomSlidableAction(
              flex: 1, // 동일한 비율로 분할 (80px씩)
              onPressed: (context) async {
                debugPrint('🔄 북마크 클릭: ${idea.title}');
                await ref.read(ideaViewModelNotifierProvider.notifier).toggleBookmarkIdea(idea.id, context);

                // 에러가 있으면 스낵바로 표시
                final error = ref.read(ideaViewModelNotifierProvider).error;
                if (error != null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(error),
                      backgroundColor: Colors.red,
                    ),
                  );
                  ref.read(ideaViewModelNotifierProvider.notifier).clearError();
                }
              },
              backgroundColor: idea.isBookmarked
                  ? Colors.blue.withOpacity(0.9) // 북마크된 경우 진한 색
                  : Colors.blue.withOpacity(0.7), // 일반 상태
              child: Icon(
                idea.isBookmarked ? CupertinoIcons.bookmark_fill : CupertinoIcons.bookmark,
                color: Colors.white,
                size: 28,
              ),
            ),
            // 삭제 버튼
            CustomSlidableAction(
              flex: 1, // 동일한 비율로 분할 (80px씩)
              onPressed: (context) async {
                debugPrint('🔄 삭제 클릭: ${idea.title}');
                final shouldDelete = await _showDeleteConfirmDialog(idea);
                if (shouldDelete == true) {
                  ref.read(ideaViewModelNotifierProvider.notifier).deleteIdea(idea.id);
                }
              },
              backgroundColor: Colors.red.withOpacity(0.7),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: const Icon(
                CupertinoIcons.trash_fill,
                color: Colors.white,
                size: 28,
              ),
            ),
          ],
        ),
        child: _buildIdeaItem(idea),
      ),
    );
  }

  Widget _buildIdeaItem(Idea idea) {
    return Container(
      decoration: BoxDecoration(
        color: idea.isPinned
            ? Colors.orange.withOpacity(0.03) // 고정된 아이디어는 살짝 오렌지 배경
            : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: idea.isPinned ? Border.all(color: Colors.orange.withOpacity(0.2), width: 1) : null,
        boxShadow: [
          BoxShadow(
            color: idea.isPinned ? Colors.orange.withOpacity(0.1) : AppColors.lightShadow,
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
            HapticFeedback.lightImpact();
            context.push('/idea-detail/${idea.id}');
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        gradient: idea.isPinned
                            ? const LinearGradient(
                                colors: [
                                  Colors.orange,
                                  Colors.deepOrange
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              )
                            : AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        idea.title,
                        style: TextStyle(
                          fontSize: AppFontSizes.ideaTitleSize,
                          fontWeight: FontWeight.bold,
                          color: idea.isPinned ? Colors.orange.shade700 : AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // 세로 점 메뉴 버튼
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _showIdeaMenuBottomSheet(idea);
                          },
                          child: const Icon(
                            CupertinoIcons.ellipsis_vertical,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (idea.content.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    idea.content,
                    style: TextStyle(
                      fontSize: AppFontSizes.ideaContentSize,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: idea.isPinned
                            ? Colors.orange.withOpacity(0.2) // 고정된 글은 더 진한 오렌지 배경
                            : AppColors.grey100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        DateFormat('yy.MM.dd HH:mm').format(idea.createdAt),
                        style: TextStyle(
                          fontSize: AppFontSizes.ideaDateSize,
                          color: idea.isPinned
                              ? Colors.orange.shade400 // 고정된 글은 오렌지 텍스트
                              : AppColors.textHint,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Spacer(), // 공간을 채워서 아이콘들을 우측으로 밀어냄
                    // 우측 하단 아이콘들 (고정, 북마크)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 고정 아이콘
                        if (idea.isPinned) ...[
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              CupertinoIcons.pin_fill,
                              size: 14,
                              color: Colors.orange.shade700,
                            ),
                          ),
                          if (idea.isBookmarked) const SizedBox(width: 6), // 간격
                        ],
                        // 북마크 아이콘
                        if (idea.isBookmarked)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              CupertinoIcons.bookmark_fill,
                              size: 14,
                              color: Colors.blue.shade700,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSection(bool isLockScreen) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.lightShadow,
            offset: const Offset(0, -4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        children: [
          // 북마크 필터 버튼
          _buildBookmarkFilterButton(),
          const SizedBox(width: 16),
          Expanded(
            child: _buildAddButton(),
          ),
          if (isLockScreen) ...[
            const SizedBox(width: 16),
            Expanded(
              child: _buildUnlockButton(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBookmarkFilterButton() {
    final ideaState = ref.watch(ideaViewModelNotifierProvider);
    final isBookmarkFilterOn = ideaState.isBookmarkFilterOn;

    return Container(
      width: 56, // 정사각형 모양
      height: 56,
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.7), // 스와이프 액션과 동일한 배경색
        borderRadius: BorderRadius.circular(16), // 다른 버튼들과 동일한 borderRadius
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.lightImpact();
            ref.read(ideaViewModelNotifierProvider.notifier).toggleBookmarkFilter();
          },
          child: Center(
            child: Icon(
              isBookmarkFilterOn
                  ? CupertinoIcons.bookmark_fill // 활성화 시 채워진 아이콘
                  : CupertinoIcons.bookmark, // 비활성화 시 빈 아이콘
              color: Colors.white, // 항상 흰색 아이콘
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return Container(
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
      child: ElevatedButton.icon(
        onPressed: () {
          // 버튼 클릭 피드백
          HapticFeedback.lightImpact();
          context.push('/add-idea');
        },
        icon: const Icon(
          CupertinoIcons.add_circled_solid,
          color: AppColors.textOnPrimary,
          size: 22,
        ),
        label: Text(
          '추가',
          style: TextStyle(
            fontSize: AppFontSizes.buttonTextSize,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.textOnPrimary,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          minimumSize: const Size.fromHeight(56),
        ),
      ),
    );
  }

  Widget _buildUnlockButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: AppColors.secondaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withOpacity(0.3),
            offset: const Offset(0, 8),
            blurRadius: 24,
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () {
          HapticFeedback.mediumImpact();
          ref.read(homeViewModelProvider.notifier).exitLockScreenMode();
        },
        icon: const Icon(
          CupertinoIcons.lock_open_fill,
          size: 20,
          color: AppColors.textOnPrimary,
        ),
        label: Text(
          '잠금해제',
          style: TextStyle(
            fontSize: AppFontSizes.buttonLargeTextSize,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.textOnPrimary,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          minimumSize: const Size.fromHeight(56),
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmDialog(Idea idea) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          '아이디어 삭제',
          style: TextStyle(
            fontSize: AppFontSizes.titleTextSize,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '이 아이디어를 삭제하시겠습니까?',
              style: TextStyle(
                fontSize: AppFontSizes.bodyTextSize,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              '취소',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: AppFontSizes.buttonTextSize,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.secondaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.of(context).pop(true);
              },
              child: Text(
                '삭제',
                style: TextStyle(
                  color: AppColors.textOnPrimary,
                  fontSize: AppFontSizes.buttonTextSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 아이디어 메뉴 바텀시트 표시
  void _showIdeaMenuBottomSheet(Idea idea) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 핸들바
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.textHint.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // 아이디어 제목 표시
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  idea.title,
                  style: TextStyle(
                    fontSize: AppFontSizes.titleTextSize,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(height: 20),

              // 메뉴 아이템들
              _buildMenuTile(
                icon: idea.isPinned ? CupertinoIcons.pin_fill : CupertinoIcons.pin,
                title: idea.isPinned ? '고정 해제' : '상단 고정',
                color: Colors.orange,
                onTap: () async {
                  Navigator.of(context).pop();
                  await ref.read(ideaViewModelNotifierProvider.notifier).togglePinIdea(idea.id, context);

                  // 에러 처리
                  final error = ref.read(ideaViewModelNotifierProvider).error;
                  if (error != null && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(error),
                        backgroundColor: Colors.red,
                      ),
                    );
                    ref.read(ideaViewModelNotifierProvider.notifier).clearError();
                  }
                },
              ),

              _buildMenuTile(
                icon: idea.isBookmarked ? CupertinoIcons.bookmark_fill : CupertinoIcons.bookmark,
                title: idea.isBookmarked ? '북마크 해제' : '북마크 추가',
                color: Colors.blue,
                onTap: () async {
                  Navigator.of(context).pop();
                  await ref.read(ideaViewModelNotifierProvider.notifier).toggleBookmarkIdea(idea.id, context);

                  // 에러 처리
                  final error = ref.read(ideaViewModelNotifierProvider).error;
                  if (error != null && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(error),
                        backgroundColor: Colors.red,
                      ),
                    );
                    ref.read(ideaViewModelNotifierProvider.notifier).clearError();
                  }
                },
              ),

              _buildMenuTile(
                icon: CupertinoIcons.trash,
                title: '삭제',
                color: Colors.red,
                onTap: () async {
                  Navigator.of(context).pop();
                  final shouldDelete = await _showDeleteConfirmDialog(idea);
                  if (shouldDelete == true) {
                    ref.read(ideaViewModelNotifierProvider.notifier).deleteIdea(idea.id);
                  }
                },
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// 메뉴 타일 위젯
  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.textHint.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: color,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: AppFontSizes.titleTextSize,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                // Icon(
                //   CupertinoIcons.chevron_right,
                //   size: 16,
                //   color: AppColors.textHint,
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 정렬 옵션 바텀시트 표시
  void _showSortBottomSheet() {
    final currentSortType = ref.read(ideaViewModelNotifierProvider).sortType;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 핸들바
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.textHint.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // 제목
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  '정렬 방식 선택',
                  style: TextStyle(
                    fontSize: AppFontSizes.headlineTextSize,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 정렬 옵션들
              ...SortType.values.map((sortType) => _buildSortTile(
                    sortType: sortType,
                    isSelected: currentSortType == sortType,
                    onTap: () {
                      Navigator.of(context).pop();
                      ref.read(ideaViewModelNotifierProvider.notifier).changeSortType(sortType);
                    },
                  )),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// 정렬 타일 위젯
  Widget _buildSortTile({
    required SortType sortType,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    IconData getIconForSortType(SortType type) {
      switch (type) {
        case SortType.newest:
          return CupertinoIcons.sort_down;
        case SortType.oldest:
          return CupertinoIcons.sort_up;
        case SortType.titleAZ:
          return CupertinoIcons.textformat_abc;
        case SortType.titleZA:
          return CupertinoIcons.textformat_abc_dottedunderline;
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.primary.withOpacity(0.3) : AppColors.textHint.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withOpacity(0.2) : AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    getIconForSortType(sortType),
                    size: 20,
                    color: isSelected ? AppColors.primary : AppColors.primary.withOpacity(0.7),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    sortType.displayName,
                    style: TextStyle(
                      fontSize: AppFontSizes.titleTextSize,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    size: 20,
                    color: AppColors.primary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
