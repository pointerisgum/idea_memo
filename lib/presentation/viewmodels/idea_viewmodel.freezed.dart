// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'idea_viewmodel.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$IdeaViewState {
  List<Idea> get ideas => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;

  /// Create a copy of IdeaViewState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $IdeaViewStateCopyWith<IdeaViewState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $IdeaViewStateCopyWith<$Res> {
  factory $IdeaViewStateCopyWith(
          IdeaViewState value, $Res Function(IdeaViewState) then) =
      _$IdeaViewStateCopyWithImpl<$Res, IdeaViewState>;
  @useResult
  $Res call({List<Idea> ideas, bool isLoading, String? error});
}

/// @nodoc
class _$IdeaViewStateCopyWithImpl<$Res, $Val extends IdeaViewState>
    implements $IdeaViewStateCopyWith<$Res> {
  _$IdeaViewStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of IdeaViewState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? ideas = null,
    Object? isLoading = null,
    Object? error = freezed,
  }) {
    return _then(_value.copyWith(
      ideas: null == ideas
          ? _value.ideas
          : ideas // ignore: cast_nullable_to_non_nullable
              as List<Idea>,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$IdeaViewStateImplCopyWith<$Res>
    implements $IdeaViewStateCopyWith<$Res> {
  factory _$$IdeaViewStateImplCopyWith(
          _$IdeaViewStateImpl value, $Res Function(_$IdeaViewStateImpl) then) =
      __$$IdeaViewStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<Idea> ideas, bool isLoading, String? error});
}

/// @nodoc
class __$$IdeaViewStateImplCopyWithImpl<$Res>
    extends _$IdeaViewStateCopyWithImpl<$Res, _$IdeaViewStateImpl>
    implements _$$IdeaViewStateImplCopyWith<$Res> {
  __$$IdeaViewStateImplCopyWithImpl(
      _$IdeaViewStateImpl _value, $Res Function(_$IdeaViewStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of IdeaViewState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? ideas = null,
    Object? isLoading = null,
    Object? error = freezed,
  }) {
    return _then(_$IdeaViewStateImpl(
      ideas: null == ideas
          ? _value._ideas
          : ideas // ignore: cast_nullable_to_non_nullable
              as List<Idea>,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$IdeaViewStateImpl implements _IdeaViewState {
  const _$IdeaViewStateImpl(
      {final List<Idea> ideas = const [], this.isLoading = false, this.error})
      : _ideas = ideas;

  final List<Idea> _ideas;
  @override
  @JsonKey()
  List<Idea> get ideas {
    if (_ideas is EqualUnmodifiableListView) return _ideas;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_ideas);
  }

  @override
  @JsonKey()
  final bool isLoading;
  @override
  final String? error;

  @override
  String toString() {
    return 'IdeaViewState(ideas: $ideas, isLoading: $isLoading, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$IdeaViewStateImpl &&
            const DeepCollectionEquality().equals(other._ideas, _ideas) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(runtimeType,
      const DeepCollectionEquality().hash(_ideas), isLoading, error);

  /// Create a copy of IdeaViewState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$IdeaViewStateImplCopyWith<_$IdeaViewStateImpl> get copyWith =>
      __$$IdeaViewStateImplCopyWithImpl<_$IdeaViewStateImpl>(this, _$identity);
}

abstract class _IdeaViewState implements IdeaViewState {
  const factory _IdeaViewState(
      {final List<Idea> ideas,
      final bool isLoading,
      final String? error}) = _$IdeaViewStateImpl;

  @override
  List<Idea> get ideas;
  @override
  bool get isLoading;
  @override
  String? get error;

  /// Create a copy of IdeaViewState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$IdeaViewStateImplCopyWith<_$IdeaViewStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
