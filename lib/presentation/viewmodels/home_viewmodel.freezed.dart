// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'home_viewmodel.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$HomeViewState {
  bool get isLoading => throw _privateConstructorUsedError;
  String get message => throw _privateConstructorUsedError;
  bool get isServiceRunning => throw _privateConstructorUsedError;
  bool get isLockScreenMode => throw _privateConstructorUsedError;
  List<AlarmInfo> get scheduledAlarms => throw _privateConstructorUsedError;

  /// Create a copy of HomeViewState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HomeViewStateCopyWith<HomeViewState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HomeViewStateCopyWith<$Res> {
  factory $HomeViewStateCopyWith(
          HomeViewState value, $Res Function(HomeViewState) then) =
      _$HomeViewStateCopyWithImpl<$Res, HomeViewState>;
  @useResult
  $Res call(
      {bool isLoading,
      String message,
      bool isServiceRunning,
      bool isLockScreenMode,
      List<AlarmInfo> scheduledAlarms});
}

/// @nodoc
class _$HomeViewStateCopyWithImpl<$Res, $Val extends HomeViewState>
    implements $HomeViewStateCopyWith<$Res> {
  _$HomeViewStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HomeViewState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? message = null,
    Object? isServiceRunning = null,
    Object? isLockScreenMode = null,
    Object? scheduledAlarms = null,
  }) {
    return _then(_value.copyWith(
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      isServiceRunning: null == isServiceRunning
          ? _value.isServiceRunning
          : isServiceRunning // ignore: cast_nullable_to_non_nullable
              as bool,
      isLockScreenMode: null == isLockScreenMode
          ? _value.isLockScreenMode
          : isLockScreenMode // ignore: cast_nullable_to_non_nullable
              as bool,
      scheduledAlarms: null == scheduledAlarms
          ? _value.scheduledAlarms
          : scheduledAlarms // ignore: cast_nullable_to_non_nullable
              as List<AlarmInfo>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$HomeViewStateImplCopyWith<$Res>
    implements $HomeViewStateCopyWith<$Res> {
  factory _$$HomeViewStateImplCopyWith(
          _$HomeViewStateImpl value, $Res Function(_$HomeViewStateImpl) then) =
      __$$HomeViewStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool isLoading,
      String message,
      bool isServiceRunning,
      bool isLockScreenMode,
      List<AlarmInfo> scheduledAlarms});
}

/// @nodoc
class __$$HomeViewStateImplCopyWithImpl<$Res>
    extends _$HomeViewStateCopyWithImpl<$Res, _$HomeViewStateImpl>
    implements _$$HomeViewStateImplCopyWith<$Res> {
  __$$HomeViewStateImplCopyWithImpl(
      _$HomeViewStateImpl _value, $Res Function(_$HomeViewStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of HomeViewState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? message = null,
    Object? isServiceRunning = null,
    Object? isLockScreenMode = null,
    Object? scheduledAlarms = null,
  }) {
    return _then(_$HomeViewStateImpl(
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      isServiceRunning: null == isServiceRunning
          ? _value.isServiceRunning
          : isServiceRunning // ignore: cast_nullable_to_non_nullable
              as bool,
      isLockScreenMode: null == isLockScreenMode
          ? _value.isLockScreenMode
          : isLockScreenMode // ignore: cast_nullable_to_non_nullable
              as bool,
      scheduledAlarms: null == scheduledAlarms
          ? _value._scheduledAlarms
          : scheduledAlarms // ignore: cast_nullable_to_non_nullable
              as List<AlarmInfo>,
    ));
  }
}

/// @nodoc

class _$HomeViewStateImpl
    with DiagnosticableTreeMixin
    implements _HomeViewState {
  const _$HomeViewStateImpl(
      {required this.isLoading,
      required this.message,
      this.isServiceRunning = false,
      this.isLockScreenMode = false,
      final List<AlarmInfo> scheduledAlarms = const []})
      : _scheduledAlarms = scheduledAlarms;

  @override
  final bool isLoading;
  @override
  final String message;
  @override
  @JsonKey()
  final bool isServiceRunning;
  @override
  @JsonKey()
  final bool isLockScreenMode;
  final List<AlarmInfo> _scheduledAlarms;
  @override
  @JsonKey()
  List<AlarmInfo> get scheduledAlarms {
    if (_scheduledAlarms is EqualUnmodifiableListView) return _scheduledAlarms;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_scheduledAlarms);
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'HomeViewState(isLoading: $isLoading, message: $message, isServiceRunning: $isServiceRunning, isLockScreenMode: $isLockScreenMode, scheduledAlarms: $scheduledAlarms)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'HomeViewState'))
      ..add(DiagnosticsProperty('isLoading', isLoading))
      ..add(DiagnosticsProperty('message', message))
      ..add(DiagnosticsProperty('isServiceRunning', isServiceRunning))
      ..add(DiagnosticsProperty('isLockScreenMode', isLockScreenMode))
      ..add(DiagnosticsProperty('scheduledAlarms', scheduledAlarms));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HomeViewStateImpl &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.isServiceRunning, isServiceRunning) ||
                other.isServiceRunning == isServiceRunning) &&
            (identical(other.isLockScreenMode, isLockScreenMode) ||
                other.isLockScreenMode == isLockScreenMode) &&
            const DeepCollectionEquality()
                .equals(other._scheduledAlarms, _scheduledAlarms));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      isLoading,
      message,
      isServiceRunning,
      isLockScreenMode,
      const DeepCollectionEquality().hash(_scheduledAlarms));

  /// Create a copy of HomeViewState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HomeViewStateImplCopyWith<_$HomeViewStateImpl> get copyWith =>
      __$$HomeViewStateImplCopyWithImpl<_$HomeViewStateImpl>(this, _$identity);
}

abstract class _HomeViewState implements HomeViewState {
  const factory _HomeViewState(
      {required final bool isLoading,
      required final String message,
      final bool isServiceRunning,
      final bool isLockScreenMode,
      final List<AlarmInfo> scheduledAlarms}) = _$HomeViewStateImpl;

  @override
  bool get isLoading;
  @override
  String get message;
  @override
  bool get isServiceRunning;
  @override
  bool get isLockScreenMode;
  @override
  List<AlarmInfo> get scheduledAlarms;

  /// Create a copy of HomeViewState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HomeViewStateImplCopyWith<_$HomeViewStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$AlarmInfo {
  int get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get message => throw _privateConstructorUsedError;
  DateTime get scheduledTime => throw _privateConstructorUsedError;
  int get delaySeconds => throw _privateConstructorUsedError;

  /// Create a copy of AlarmInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AlarmInfoCopyWith<AlarmInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AlarmInfoCopyWith<$Res> {
  factory $AlarmInfoCopyWith(AlarmInfo value, $Res Function(AlarmInfo) then) =
      _$AlarmInfoCopyWithImpl<$Res, AlarmInfo>;
  @useResult
  $Res call(
      {int id,
      String title,
      String message,
      DateTime scheduledTime,
      int delaySeconds});
}

/// @nodoc
class _$AlarmInfoCopyWithImpl<$Res, $Val extends AlarmInfo>
    implements $AlarmInfoCopyWith<$Res> {
  _$AlarmInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AlarmInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? message = null,
    Object? scheduledTime = null,
    Object? delaySeconds = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      scheduledTime: null == scheduledTime
          ? _value.scheduledTime
          : scheduledTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      delaySeconds: null == delaySeconds
          ? _value.delaySeconds
          : delaySeconds // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AlarmInfoImplCopyWith<$Res>
    implements $AlarmInfoCopyWith<$Res> {
  factory _$$AlarmInfoImplCopyWith(
          _$AlarmInfoImpl value, $Res Function(_$AlarmInfoImpl) then) =
      __$$AlarmInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      String title,
      String message,
      DateTime scheduledTime,
      int delaySeconds});
}

/// @nodoc
class __$$AlarmInfoImplCopyWithImpl<$Res>
    extends _$AlarmInfoCopyWithImpl<$Res, _$AlarmInfoImpl>
    implements _$$AlarmInfoImplCopyWith<$Res> {
  __$$AlarmInfoImplCopyWithImpl(
      _$AlarmInfoImpl _value, $Res Function(_$AlarmInfoImpl) _then)
      : super(_value, _then);

  /// Create a copy of AlarmInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? message = null,
    Object? scheduledTime = null,
    Object? delaySeconds = null,
  }) {
    return _then(_$AlarmInfoImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      scheduledTime: null == scheduledTime
          ? _value.scheduledTime
          : scheduledTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      delaySeconds: null == delaySeconds
          ? _value.delaySeconds
          : delaySeconds // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$AlarmInfoImpl with DiagnosticableTreeMixin implements _AlarmInfo {
  const _$AlarmInfoImpl(
      {required this.id,
      required this.title,
      required this.message,
      required this.scheduledTime,
      required this.delaySeconds});

  @override
  final int id;
  @override
  final String title;
  @override
  final String message;
  @override
  final DateTime scheduledTime;
  @override
  final int delaySeconds;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'AlarmInfo(id: $id, title: $title, message: $message, scheduledTime: $scheduledTime, delaySeconds: $delaySeconds)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'AlarmInfo'))
      ..add(DiagnosticsProperty('id', id))
      ..add(DiagnosticsProperty('title', title))
      ..add(DiagnosticsProperty('message', message))
      ..add(DiagnosticsProperty('scheduledTime', scheduledTime))
      ..add(DiagnosticsProperty('delaySeconds', delaySeconds));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AlarmInfoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.scheduledTime, scheduledTime) ||
                other.scheduledTime == scheduledTime) &&
            (identical(other.delaySeconds, delaySeconds) ||
                other.delaySeconds == delaySeconds));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, id, title, message, scheduledTime, delaySeconds);

  /// Create a copy of AlarmInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AlarmInfoImplCopyWith<_$AlarmInfoImpl> get copyWith =>
      __$$AlarmInfoImplCopyWithImpl<_$AlarmInfoImpl>(this, _$identity);
}

abstract class _AlarmInfo implements AlarmInfo {
  const factory _AlarmInfo(
      {required final int id,
      required final String title,
      required final String message,
      required final DateTime scheduledTime,
      required final int delaySeconds}) = _$AlarmInfoImpl;

  @override
  int get id;
  @override
  String get title;
  @override
  String get message;
  @override
  DateTime get scheduledTime;
  @override
  int get delaySeconds;

  /// Create a copy of AlarmInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AlarmInfoImplCopyWith<_$AlarmInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
