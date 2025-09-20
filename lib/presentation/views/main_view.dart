import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../viewmodels/idea_viewmodel.dart';
import '../viewmodels/home_viewmodel.dart';
import '../../domain/entities/idea.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/snackbar_utils.dart';

class MainView extends ConsumerStatefulWidget {
  const MainView({super.key});

  @override
  ConsumerState<MainView> createState() => _MainViewState();
}

class _MainViewState extends ConsumerState<MainView> with WidgetsBindingObserver {
  Timer? _timer;
  DateTime _currentTime = DateTime.now();
  bool _hasShownPermissionSheet = false;
  bool _isPermissionSheetShowing = false; // 현재 바텀시트가 표시 중인지 추적

  @override
  void initState() {
    super.initState();
    // 1초마다 시간 업데이트
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });

    // 앱 생명주기 관찰자 등록
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _timer?.cancel();
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
              child: _buildIdeaList(ideaState.ideas),
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
                const Text(
                  '편리한 이용을 위해\n아래의 접근권한 허용이 필요합니다',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
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
                              const Text(
                                '다른 앱 위에 표시',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '(필수)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '앱 서비스 실행',
                            style: TextStyle(
                              fontSize: 12,
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
                    child: const Text(
                      '동의',
                      style: TextStyle(
                        fontSize: 14,
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
    final dateFormatter = DateFormat('yyyy년 MM월 dd일');
    final timeFormatter = DateFormat('HH:mm');

    return Container(
      height: 90,
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
      child: Row(
        children: [
          const SizedBox(width: 50),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  dateFormatter.format(_currentTime),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textOnPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeFormatter.format(_currentTime),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textOnPrimary,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            margin: const EdgeInsets.only(right: 16),
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
                SnackBarUtils.showInfo(context, '설정 화면은 추후 구현 예정입니다');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdeaList(List<Idea> ideas) {
    if (ideas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppColors.accentGradient,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.3),
                    offset: const Offset(0, 8),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: const Icon(
                CupertinoIcons.lightbulb_fill,
                size: 36,
                color: AppColors.textOnPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '아직 아이디어가 없습니다',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '새로운 아이디어를 추가해보세요!',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      );
    }

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
    return Dismissible(
      key: Key(idea.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await _showDeleteConfirmDialog(idea);
      },
      onDismissed: (direction) {
        ref.read(ideaViewModelNotifierProvider.notifier).deleteIdea(idea.id);
        SnackBarUtils.showSuccess(context, '아이디어가 삭제되었습니다');
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: AppColors.secondaryGradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '삭제',
              style: TextStyle(
                color: AppColors.textOnPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                CupertinoIcons.trash_fill,
                color: AppColors.textOnPrimary,
                size: 20,
              ),
            ),
          ],
        ),
      ),
      child: _buildIdeaItem(idea),
    );
  }

  Widget _buildIdeaItem(Idea idea) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    idea.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (idea.content.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                idea.content,
                style: TextStyle(
                  fontSize: 14,
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
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    DateFormat('MM/dd HH:mm').format(idea.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
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
        label: const Text(
          '추가',
          style: TextStyle(
            fontSize: 14,
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
        label: const Text(
          '잠금해제',
          style: TextStyle(
            fontSize: 16,
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
        title: const Text(
          '아이디어 삭제',
          style: TextStyle(
            fontSize: 16,
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
                fontSize: 14,
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
                fontSize: 14,
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
              child: const Text(
                '삭제',
                style: TextStyle(
                  color: AppColors.textOnPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
