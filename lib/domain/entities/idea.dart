import 'package:freezed_annotation/freezed_annotation.dart';

part 'idea.freezed.dart';
part 'idea.g.dart';

@freezed
class Idea with _$Idea {
  const factory Idea({
    required String id,
    required String title,
    required String content,
    required DateTime createdAt,
    DateTime? updatedAt,
    @Default(false) bool isPinned, // 고정 여부
    DateTime? pinnedAt, // 고정된 시간
    @Default(false) bool isBookmarked, // 북마크 여부
    DateTime? bookmarkedAt, // 북마크된 시간
  }) = _Idea;

  factory Idea.fromJson(Map<String, dynamic> json) => _$IdeaFromJson(json);
}
