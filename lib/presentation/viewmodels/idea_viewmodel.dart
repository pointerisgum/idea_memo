import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ideamemo/domain/entities/idea.dart';
import 'package:ideamemo/core/services/firestore_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ideamemo/core/utils/snackbar_utils.dart';

part 'idea_viewmodel.g.dart';
part 'idea_viewmodel.freezed.dart';

/// 아이디어 정렬 타입
enum SortType {
  newest('최신순'),
  oldest('오래된순'),
  titleAZ('제목순 (A-Z)'),
  titleZA('제목순 (Z-A)');

  const SortType(this.displayName);
  final String displayName;
}

@freezed
class IdeaViewState with _$IdeaViewState {
  const factory IdeaViewState({
    @Default([]) List<Idea> ideas,
    @Default(false) bool isLoading,
    @Default(false) bool isBookmarkFilterOn, // 북마크 필터 상태
    @Default(SortType.newest) SortType sortType, // 정렬 타입
    String? error,
  }) = _IdeaViewState;
}

@riverpod
class IdeaViewModelNotifier extends _$IdeaViewModelNotifier {
  @override
  IdeaViewState build() {
    // 초기 상태만 반환, 데이터 로딩은 별도로 처리
    return const IdeaViewState();
  }

  /// Firestore에서 아이디어 목록 로드
  Future<void> loadIdeas() async {
    state = state.copyWith(isLoading: true);

    try {
      final ideas = await FirestoreService.getIdeas();

      // 현재 정렬 타입에 따라 정렬
      final sortedIdeas = _sortIdeasBySortType(ideas, state.sortType);

      state = state.copyWith(
        ideas: sortedIdeas,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      debugPrint('❌ [IDEA_VM] 아이디어 로드 실패: $e');
      state = state.copyWith(
        error: '아이디어를 불러오는데 실패했습니다: $e',
        isLoading: false,
      );
    }
  }

  /// 새 아이디어 추가
  Future<void> addIdea({
    required String title,
    required String content,
  }) async {
    if (title.trim().isEmpty) return;

    try {
      final newIdea = Idea(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title.trim(),
        content: content.trim(),
        createdAt: DateTime.now(),
      );

      // Firestore에 저장
      await FirestoreService.addIdea(newIdea);

      // 로컬 상태 업데이트 (현재 정렬 타입으로 정렬)
      final updatedIdeas = [
        newIdea,
        ...state.ideas
      ];

      final sortedIdeas = _sortIdeasBySortType(updatedIdeas, state.sortType);

      state = state.copyWith(
        ideas: sortedIdeas,
        error: null,
      );

      debugPrint('✅ [IDEA_VM] 아이디어 추가 성공: ${newIdea.id}');
    } catch (e) {
      debugPrint('❌ [IDEA_VM] 아이디어 추가 실패: $e');
      state = state.copyWith(
        error: '아이디어 추가에 실패했습니다: $e',
      );
    }
  }

  /// 아이디어 수정
  Future<void> updateIdea(String id, {String? title, String? content}) async {
    try {
      final updatedIdeas = state.ideas.map((idea) {
        if (idea.id == id) {
          return idea.copyWith(
            title: title ?? idea.title,
            content: content ?? idea.content,
            updatedAt: DateTime.now(),
          );
        }
        return idea;
      }).toList();

      // 수정된 아이디어 찾기
      final updatedIdea = updatedIdeas.firstWhere((idea) => idea.id == id);

      // Firestore에 업데이트
      await FirestoreService.updateIdea(updatedIdea);

      // 로컬 상태 업데이트
      state = state.copyWith(
        ideas: updatedIdeas,
        error: null,
      );

      debugPrint('✅ [IDEA_VM] 아이디어 수정 성공: $id');
    } catch (e) {
      debugPrint('❌ [IDEA_VM] 아이디어 수정 실패: $e');
      state = state.copyWith(
        error: '아이디어 수정에 실패했습니다: $e',
      );
    }
  }

  /// 아이디어 삭제
  Future<void> deleteIdea(String id) async {
    try {
      // Firestore에서 삭제
      await FirestoreService.deleteIdea(id);

      // 로컬 상태 업데이트
      final updatedIdeas = state.ideas.where((idea) => idea.id != id).toList();

      state = state.copyWith(
        ideas: updatedIdeas,
        error: null,
      );

      debugPrint('✅ [IDEA_VM] 아이디어 삭제 성공: $id');
    } catch (e) {
      debugPrint('❌ [IDEA_VM] 아이디어 삭제 실패: $e');
      state = state.copyWith(
        error: '아이디어 삭제에 실패했습니다: $e',
      );
    }
  }

  /// 아이디어 고정/해제 토글
  Future<void> togglePinIdea(String id, BuildContext? context) async {
    try {
      // 현재 상태 확인
      final currentIdea = state.ideas.firstWhere((idea) => idea.id == id);
      final willBePinned = !currentIdea.isPinned;

      // Firestore에서 고정 토글
      await FirestoreService.togglePinIdea(id);

      // 로컬 상태 업데이트
      final updatedIdeas = state.ideas.map((idea) {
        if (idea.id == id) {
          final newIsPinned = !idea.isPinned;
          return idea.copyWith(
            isPinned: newIsPinned,
            pinnedAt: newIsPinned ? DateTime.now() : null,
          );
        }
        return idea;
      }).toList();

      // 현재 정렬 타입으로 재정렬
      final sortedIdeas = _sortIdeasBySortType(updatedIdeas, state.sortType);

      state = state.copyWith(
        ideas: sortedIdeas,
        error: null,
      );

      // 스낵바 표시
      if (context != null && context.mounted) {
        SnackbarUtils.showPin(context, willBePinned ? '아이디어를 상단에 고정했습니다' : '아이디어 고정을 해제했습니다');
      }

      debugPrint('✅ [IDEA_VM] 아이디어 고정 토글 성공: $id');
    } catch (e) {
      debugPrint('❌ [IDEA_VM] 아이디어 고정 토글 실패: $e');
      state = state.copyWith(
        error: e.toString().contains('최대 3개') ? '고정할 수 있는 아이디어는 최대 3개입니다.' : '고정 처리 중 오류가 발생했습니다: $e',
      );
    }
  }

  /// 고정 우선순위로 아이디어 정렬
  /// 1순위: 고정된 아이디어들 (pinnedAt 최신순)
  /// 2순위: 일반 아이디어들 (createdAt 최신순)
  List<Idea> _sortIdeasByPinPriority(List<Idea> ideas) {
    final pinnedIdeas = ideas.where((idea) => idea.isPinned).toList();
    final unpinnedIdeas = ideas.where((idea) => !idea.isPinned).toList();

    // 고정된 아이디어들을 pinnedAt 기준 최신순 정렬
    pinnedIdeas.sort((a, b) {
      if (a.pinnedAt == null && b.pinnedAt == null) return 0;
      if (a.pinnedAt == null) return 1;
      if (b.pinnedAt == null) return -1;
      return b.pinnedAt!.compareTo(a.pinnedAt!);
    });

    // 일반 아이디어들을 createdAt 기준 최신순 정렬
    unpinnedIdeas.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // 고정된 아이디어를 먼저, 그 다음 일반 아이디어
    return [
      ...pinnedIdeas,
      ...unpinnedIdeas
    ];
  }

  /// 아이디어 북마크/해제 토글
  Future<void> toggleBookmarkIdea(String id, BuildContext? context) async {
    try {
      // 현재 상태 확인
      final currentIdea = state.ideas.firstWhere((idea) => idea.id == id);
      final willBeBookmarked = !currentIdea.isBookmarked;

      // Firestore에서 북마크 토글
      await FirestoreService.toggleBookmarkIdea(id);

      // 로컬 상태 업데이트
      final updatedIdeas = state.ideas.map((idea) {
        if (idea.id == id) {
          final newIsBookmarked = !idea.isBookmarked;
          return idea.copyWith(
            isBookmarked: newIsBookmarked,
            bookmarkedAt: newIsBookmarked ? DateTime.now() : null,
          );
        }
        return idea;
      }).toList();

      // 현재 정렬 타입으로 재정렬
      final sortedIdeas = _sortIdeasBySortType(updatedIdeas, state.sortType);

      state = state.copyWith(
        ideas: sortedIdeas,
        error: null,
      );

      // 스낵바 표시
      if (context != null && context.mounted) {
        SnackbarUtils.showBookmark(context, willBeBookmarked ? '북마크에 추가했습니다' : '북마크에서 제거했습니다');
      }

      debugPrint('✅ [IDEA_VM] 아이디어 북마크 토글 성공: $id');
    } catch (e) {
      debugPrint('❌ [IDEA_VM] 아이디어 북마크 토글 실패: $e');
      state = state.copyWith(
        error: '북마크 처리 중 오류가 발생했습니다: $e',
      );
    }
  }

  /// 북마크 필터 토글
  void toggleBookmarkFilter() {
    final newFilterState = !state.isBookmarkFilterOn;
    state = state.copyWith(isBookmarkFilterOn: newFilterState);
    debugPrint('🔄 [IDEA_VM] 북마크 필터 토글: $newFilterState');
  }

  /// 정렬 타입 변경
  void changeSortType(SortType newSortType) {
    if (state.sortType == newSortType) return;

    // 정렬 타입 변경 및 데이터 재정렬
    final sortedIdeas = _sortIdeasBySortType(state.ideas, newSortType);

    state = state.copyWith(
      sortType: newSortType,
      ideas: sortedIdeas,
    );

    debugPrint('🔄 [IDEA_VM] 정렬 타입 변경: ${newSortType.displayName}');
  }

  /// 정렬 타입에 따른 아이디어 정렬
  List<Idea> _sortIdeasBySortType(List<Idea> ideas, SortType sortType) {
    final sortedIdeas = List<Idea>.from(ideas);

    switch (sortType) {
      case SortType.newest:
        // 고정 우선순위 + 최신순
        return _sortIdeasByPinPriority(sortedIdeas);

      case SortType.oldest:
        // 고정 우선순위 + 오래된순
        final pinnedIdeas = sortedIdeas.where((idea) => idea.isPinned).toList();
        final unpinnedIdeas = sortedIdeas.where((idea) => !idea.isPinned).toList();

        // 고정된 아이디어들을 pinnedAt 기준 오래된순 정렬
        pinnedIdeas.sort((a, b) {
          if (a.pinnedAt == null && b.pinnedAt == null) return 0;
          if (a.pinnedAt == null) return 1;
          if (b.pinnedAt == null) return -1;
          return a.pinnedAt!.compareTo(b.pinnedAt!);
        });

        // 일반 아이디어들을 createdAt 기준 오래된순 정렬
        unpinnedIdeas.sort((a, b) => a.createdAt.compareTo(b.createdAt));

        return [
          ...pinnedIdeas,
          ...unpinnedIdeas
        ];

      case SortType.titleAZ:
        // 고정 우선순위 + 제목 A-Z
        final pinnedIdeas = sortedIdeas.where((idea) => idea.isPinned).toList();
        final unpinnedIdeas = sortedIdeas.where((idea) => !idea.isPinned).toList();

        pinnedIdeas.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        unpinnedIdeas.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

        return [
          ...pinnedIdeas,
          ...unpinnedIdeas
        ];

      case SortType.titleZA:
        // 고정 우선순위 + 제목 Z-A
        final pinnedIdeas = sortedIdeas.where((idea) => idea.isPinned).toList();
        final unpinnedIdeas = sortedIdeas.where((idea) => !idea.isPinned).toList();

        pinnedIdeas.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
        unpinnedIdeas.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));

        return [
          ...pinnedIdeas,
          ...unpinnedIdeas
        ];
    }
  }

  /// 필터링된 아이디어 목록 반환
  List<Idea> get filteredIdeas {
    if (state.isBookmarkFilterOn) {
      return state.ideas.where((idea) => idea.isBookmarked).toList();
    }
    return state.ideas;
  }

  /// 에러 메시지 클리어
  void clearError() {
    state = state.copyWith(error: null);
  }
}
