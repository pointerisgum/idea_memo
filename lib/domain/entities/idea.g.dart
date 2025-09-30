// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'idea.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$IdeaImpl _$$IdeaImplFromJson(Map<String, dynamic> json) => _$IdeaImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      isPinned: json['isPinned'] as bool? ?? false,
      pinnedAt: json['pinnedAt'] == null
          ? null
          : DateTime.parse(json['pinnedAt'] as String),
      isBookmarked: json['isBookmarked'] as bool? ?? false,
      bookmarkedAt: json['bookmarkedAt'] == null
          ? null
          : DateTime.parse(json['bookmarkedAt'] as String),
    );

Map<String, dynamic> _$$IdeaImplToJson(_$IdeaImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'content': instance.content,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'isPinned': instance.isPinned,
      'pinnedAt': instance.pinnedAt?.toIso8601String(),
      'isBookmarked': instance.isBookmarked,
      'bookmarkedAt': instance.bookmarkedAt?.toIso8601String(),
    };
