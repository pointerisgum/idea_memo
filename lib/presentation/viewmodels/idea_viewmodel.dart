import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:convert';
import '../../domain/entities/idea.dart';

part 'idea_viewmodel.g.dart';
part 'idea_viewmodel.freezed.dart';

@freezed
class IdeaViewState with _$IdeaViewState {
  const factory IdeaViewState({
    @Default([]) List<Idea> ideas,
    @Default(false) bool isLoading,
    String? error,
  }) = _IdeaViewState;
}

@riverpod
class IdeaViewModelNotifier extends _$IdeaViewModelNotifier {
  static const String _ideasKey = 'ideas_list';

  @override
  IdeaViewState build() {
    _loadIdeas();
    return const IdeaViewState();
  }

  Future<void> _loadIdeas() async {
    state = state.copyWith(isLoading: true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final ideasJson = prefs.getStringList(_ideasKey) ?? [];

      final ideas = ideasJson.map((json) => Idea.fromJson(jsonDecode(json))).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // 최신순 정렬

      state = state.copyWith(
        ideas: ideas,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: '아이디어를 불러오는데 실패했습니다: $e',
        isLoading: false,
      );
    }
  }

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

      final updatedIdeas = [
        newIdea,
        ...state.ideas
      ];

      await _saveIdeas(updatedIdeas);

      state = state.copyWith(
        ideas: updatedIdeas,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        error: '아이디어 추가에 실패했습니다: $e',
      );
    }
  }

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

      await _saveIdeas(updatedIdeas);

      state = state.copyWith(
        ideas: updatedIdeas,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        error: '아이디어 수정에 실패했습니다: $e',
      );
    }
  }

  Future<void> deleteIdea(String id) async {
    try {
      final updatedIdeas = state.ideas.where((idea) => idea.id != id).toList();

      await _saveIdeas(updatedIdeas);

      state = state.copyWith(
        ideas: updatedIdeas,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        error: '아이디어 삭제에 실패했습니다: $e',
      );
    }
  }

  Future<void> _saveIdeas(List<Idea> ideas) async {
    final prefs = await SharedPreferences.getInstance();
    final ideasJson = ideas.map((idea) => jsonEncode(idea.toJson())).toList();

    await prefs.setStringList(_ideasKey, ideasJson);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}
