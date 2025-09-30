// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'font_size_viewmodel.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$FontSizeState {
  FontSizeType get currentFontSize => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;

  /// Create a copy of FontSizeState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FontSizeStateCopyWith<FontSizeState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FontSizeStateCopyWith<$Res> {
  factory $FontSizeStateCopyWith(
          FontSizeState value, $Res Function(FontSizeState) then) =
      _$FontSizeStateCopyWithImpl<$Res, FontSizeState>;
  @useResult
  $Res call({FontSizeType currentFontSize, bool isLoading});
}

/// @nodoc
class _$FontSizeStateCopyWithImpl<$Res, $Val extends FontSizeState>
    implements $FontSizeStateCopyWith<$Res> {
  _$FontSizeStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FontSizeState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentFontSize = null,
    Object? isLoading = null,
  }) {
    return _then(_value.copyWith(
      currentFontSize: null == currentFontSize
          ? _value.currentFontSize
          : currentFontSize // ignore: cast_nullable_to_non_nullable
              as FontSizeType,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FontSizeStateImplCopyWith<$Res>
    implements $FontSizeStateCopyWith<$Res> {
  factory _$$FontSizeStateImplCopyWith(
          _$FontSizeStateImpl value, $Res Function(_$FontSizeStateImpl) then) =
      __$$FontSizeStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({FontSizeType currentFontSize, bool isLoading});
}

/// @nodoc
class __$$FontSizeStateImplCopyWithImpl<$Res>
    extends _$FontSizeStateCopyWithImpl<$Res, _$FontSizeStateImpl>
    implements _$$FontSizeStateImplCopyWith<$Res> {
  __$$FontSizeStateImplCopyWithImpl(
      _$FontSizeStateImpl _value, $Res Function(_$FontSizeStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of FontSizeState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentFontSize = null,
    Object? isLoading = null,
  }) {
    return _then(_$FontSizeStateImpl(
      currentFontSize: null == currentFontSize
          ? _value.currentFontSize
          : currentFontSize // ignore: cast_nullable_to_non_nullable
              as FontSizeType,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$FontSizeStateImpl
    with DiagnosticableTreeMixin
    implements _FontSizeState {
  const _$FontSizeStateImpl(
      {this.currentFontSize = FontSizeType.medium, this.isLoading = false});

  @override
  @JsonKey()
  final FontSizeType currentFontSize;
  @override
  @JsonKey()
  final bool isLoading;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'FontSizeState(currentFontSize: $currentFontSize, isLoading: $isLoading)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'FontSizeState'))
      ..add(DiagnosticsProperty('currentFontSize', currentFontSize))
      ..add(DiagnosticsProperty('isLoading', isLoading));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FontSizeStateImpl &&
            (identical(other.currentFontSize, currentFontSize) ||
                other.currentFontSize == currentFontSize) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading));
  }

  @override
  int get hashCode => Object.hash(runtimeType, currentFontSize, isLoading);

  /// Create a copy of FontSizeState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FontSizeStateImplCopyWith<_$FontSizeStateImpl> get copyWith =>
      __$$FontSizeStateImplCopyWithImpl<_$FontSizeStateImpl>(this, _$identity);
}

abstract class _FontSizeState implements FontSizeState {
  const factory _FontSizeState(
      {final FontSizeType currentFontSize,
      final bool isLoading}) = _$FontSizeStateImpl;

  @override
  FontSizeType get currentFontSize;
  @override
  bool get isLoading;

  /// Create a copy of FontSizeState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FontSizeStateImplCopyWith<_$FontSizeStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
