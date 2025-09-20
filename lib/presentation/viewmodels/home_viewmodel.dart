import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'home_viewmodel.g.dart';
part 'home_viewmodel.freezed.dart';

@riverpod
class HomeViewModel extends _$HomeViewModel {
  static const MethodChannel _autoLockScreenChannel = MethodChannel('auto_lockscreen_channel');
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  // 알람 중복 방지를 위한 처리된 알람 ID 관리
  static const String _processedAlarmsKey = 'processed_alarm_ids';

  // Navigation을 위한 BuildContext 저장
  BuildContext? _context;

  Future<Set<int>> _loadProcessedAlarmIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? stringList = prefs.getStringList(_processedAlarmsKey);
      if (stringList != null) {
        return stringList.map((str) => int.parse(str)).toSet();
      }
    } catch (e) {
      debugPrint('처리된 알람 ID 로드 실패: $e');
    }
    return <int>{};
  }

  Future<void> _saveProcessedAlarmIds(Set<int> alarmIds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> stringList = alarmIds.map((id) => id.toString()).toList();
      await prefs.setStringList(_processedAlarmsKey, stringList);
    } catch (e) {
      debugPrint('처리된 알람 ID 저장 실패: $e');
    }
  }

  Future<void> _addProcessedAlarmId(int alarmId) async {
    final processedIds = await _loadProcessedAlarmIds();
    processedIds.add(alarmId);

    if (processedIds.length > 100) {
      final recentIds = processedIds.toList()..sort();
      final keepIds = recentIds.skip(recentIds.length - 50).toSet();
      await _saveProcessedAlarmIds(keepIds);
    } else {
      await _saveProcessedAlarmIds(processedIds);
    }
  }

  Future<bool> _isAlarmProcessed(int alarmId) async {
    final processedIds = await _loadProcessedAlarmIds();
    return processedIds.contains(alarmId);
  }

  @override
  HomeViewState build() {
    final initialState = const HomeViewState(
      isLoading: true, // 권한 체크 중
      isServiceRunning: false,
      isLockScreenMode: false,
      needsPermissionSetup: false, // 초기값은 false
    );

    Future.microtask(() async {
      try {
        await _initializeNotifications();
        await _checkLockScreenMode();
        _setupMethodChannelListener();

        // 최우선으로 오버레이 권한 체크
        await _checkOverlayPermissionAndSetState();

        debugPrint('✅ 초기화 완료');
      } catch (e, stackTrace) {
        debugPrint('❌ 초기화 중 오류: $e');
        debugPrint('❌ Stack trace: $stackTrace');
        _setLoading(false);
      }
    });

    return initialState;
  }

  Future<void> _initializeNotifications() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
      final bool? initialized = await _notificationsPlugin.initialize(initializationSettings);
      debugPrint('📱 Notification 초기화 결과: $initialized');
    } catch (e) {
      debugPrint('Notification 초기화 실패: $e');
    }
  }

  // 백그라운드 서비스 시작 (권한 허용 후에만 호출)
  Future<void> _autoStartService() async {
    if (!Platform.isAndroid) return;

    try {
      _setLoading(true);
      await _autoLockScreenChannel.invokeMethod('checkAndStartService');
      _setServiceRunning(true);
      debugPrint('✅ 백그라운드 서비스 시작됨');
    } catch (e) {
      debugPrint('❌ 서비스 시작 실패: $e');
      _setServiceRunning(false);
    }

    _setLoading(false);
  }

  // 로딩 상태 업데이트
  void _setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  // 최우선 권한 체크 및 상태 설정
  Future<void> _checkOverlayPermissionAndSetState() async {
    if (!Platform.isAndroid) {
      // iOS는 권한 불필요
      state = state.copyWith(
        isLoading: false,
        needsPermissionSetup: false,
      );
      return;
    }

    try {
      // 네이티브에서 오버레이 권한 상태 확인
      final hasPermission = await _autoLockScreenChannel.invokeMethod('checkOverlayPermission');
      debugPrint('🔍 오버레이 권한 상태: $hasPermission');

      if (hasPermission == true) {
        // 권한 있음 - 바로 서비스 시작, 팝업 없음
        debugPrint('✅ 권한 있음 - 서비스 시작');
        state = state.copyWith(
          isLoading: false,
          needsPermissionSetup: false,
        );
        await _autoStartService();
      } else {
        // 권한 없음 - 권한 요청 팝업 필요
        debugPrint('⚠️ 권한 없음 - 팝업 표시 필요');
        state = state.copyWith(
          isLoading: false,
          needsPermissionSetup: true,
        );
      }
    } catch (e) {
      debugPrint('❌ 권한 체크 실패: $e');
      // 오류 시 권한 요청으로 처리
      state = state.copyWith(
        isLoading: false,
        needsPermissionSetup: true,
      );
    }
  }

  // 권한 요청 메서드
  Future<void> requestOverlayPermission() async {
    if (!Platform.isAndroid) return;

    try {
      debugPrint('🔄 오버레이 권한 요청 시작');
      // 직접 권한 요청 메서드 호출 (checkAndStartService가 아님!)
      await _autoLockScreenChannel.invokeMethod('requestOverlayPermission');
      debugPrint('✅ 권한 요청 완료');
    } catch (e) {
      debugPrint('❌ 권한 요청 실패: $e');
    }
  }

  // 외부에서 권한 체크할 수 있는 공개 메서드
  Future<bool> checkOverlayPermission() async {
    if (!Platform.isAndroid) return true;

    try {
      final hasPermission = await _autoLockScreenChannel.invokeMethod('checkOverlayPermission');
      return hasPermission == true;
    } catch (e) {
      debugPrint('❌ 권한 체크 실패: $e');
      return false;
    }
  }

  // 메시지 업데이트 (더 이상 사용하지 않음)
  void _setMessage(String message) {
    // message 필드가 제거되어 아무것도 하지 않음
    debugPrint('메시지: $message');
  }

  // 서비스 실행 상태 업데이트
  void _setServiceRunning(bool isRunning) {
    state = state.copyWith(isServiceRunning: isRunning);
  }

  // 다중 알람 등록 (지정된 초 후)
  Future<void> scheduleAlarmWithDelay(int delaySeconds) async {
    _setLoading(true);
    _setMessage('알람을 등록하고 있습니다...');

    try {
      // Android 12+ 정확한 알람 권한 확인
      if (Platform.isAndroid) {
        final exactAlarmPermission = await Permission.scheduleExactAlarm.status;
        if (exactAlarmPermission != PermissionStatus.granted) {
          _setMessage('정확한 알람 권한이 필요합니다. 권한을 허용해주세요.');
          final result = await Permission.scheduleExactAlarm.request();
          if (result != PermissionStatus.granted) {
            _setMessage('❌ 정확한 알람 권한이 거부되어 알람을 설정할 수 없습니다.');
            _setLoading(false);
            return;
          }
        }
      }
      // Android 전체 화면 알림 설정 (릴리즈 모드 안전성 강화)
      final AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'alarm_channel',
        'Alarm Notifications',
        channelDescription: 'Channel for Alarm notifications',
        importance: Importance.max,
        priority: Priority.high,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        showWhen: true,
        when: null,
        usesChronometer: false,
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList(<int>[
          0,
          1000,
          500,
          1000
        ]),
        actions: <AndroidNotificationAction>[
          const AndroidNotificationAction(
            'snooze_action',
            '5분 후',
          ),
          const AndroidNotificationAction(
            'dismiss_action',
            '해제',
          ),
        ],
      );

      // iOS 알림 설정
      const DarwinNotificationDetails iOSPlatformChannelSpecifics = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        badgeNumber: 1,
        categoryIdentifier: 'alarm_category',
      );

      final NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      // 안전한 timezone 처리 (릴리즈 모드 대응)
      late tz.TZDateTime scheduledTime;
      try {
        scheduledTime = tz.TZDateTime.now(tz.local).add(Duration(seconds: delaySeconds));
      } catch (e) {
        debugPrint('❌ Timezone 오류, UTC 사용: $e');
        // timezone 실패 시 UTC 사용
        final utcTime = DateTime.now().toUtc().add(Duration(seconds: delaySeconds));
        scheduledTime = tz.TZDateTime.from(utcTime, tz.UTC);
      }

      // 고유한 알람 ID 생성 (현재 시간 기반으로 중복 방지)
      final int alarmId = DateTime.now().millisecondsSinceEpoch % 2147483647;

      String timeText = _formatDelayTime(delaySeconds);
      final String title = 'TODO 알람 #$alarmId';
      final String message = '$timeText 후 알람입니다!';

      // 릴리즈 모드 대응: zonedSchedule 시도
      try {
        await _notificationsPlugin.zonedSchedule(
          alarmId,
          title,
          message,
          scheduledTime,
          platformChannelSpecifics,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'alarm_payload_$alarmId',
        );
        debugPrint('✅ zonedSchedule 성공');
      } catch (e) {
        debugPrint('❌ zonedSchedule 실패: $e');
        debugPrint('🔄 WorkManager를 통한 알람만 사용');
        // WorkManager를 통한 알람은 아래에서 설정되므로 계속 진행
      }

      // 알람 목록에 추가
      final alarmInfo = AlarmInfo(
        id: alarmId,
        title: title,
        message: message,
        scheduledTime: scheduledTime.toLocal(),
        delaySeconds: delaySeconds,
      );

      _addAlarmToList(alarmInfo);

      _setMessage('✅ 알람이 $timeText 후로 등록되었습니다! (ID: $alarmId)');

      // WorkManager로 확실한 알람 스케줄링 (앱 종료와 무관)
      await _autoLockScreenChannel.invokeMethod('scheduleWorkManagerAlarm', {
        'alarmId': alarmId,
        'delaySeconds': delaySeconds,
        'title': title,
        'message': message,
      });

      debugPrint('✅ WorkManager 알람 스케줄링 요청 완료');
    } catch (e) {
      debugPrint('❌ 알람 등록 오류 상세: $e');
      debugPrint('❌ 오류 타입: ${e.runtimeType}');
      if (e is PlatformException) {
        debugPrint('❌ PlatformException - code: ${e.code}, message: ${e.message}');
      }
      _setMessage('알람 등록 중 오류가 발생했습니다: $e\n\n오류 타입: ${e.runtimeType}');
    }

    _setLoading(false);
  }

  // Navigation 기반 전체 화면 알람 표시
  void _showNavigationAlarm() {
    debugPrint('🚨 _showNavigationAlarm 호출됨!');
    try {
      // Android: 네이티브 채널로 화면 깨우기 + 사운드 재생 요청
      if (Platform.isAndroid) {
        _autoLockScreenChannel.invokeMethod('showFullScreenAlarm', {
          'title': 'TODO 알람 123 ',
          'message': '등록된 할 일 시간입니다! 123',
        });
        debugPrint('🔔 Android 네이티브 알람 요청 전송 완료');
      }

      // iOS는 기본 알림만 사용 (Navigation 안함)
      if (Platform.isIOS) {
        debugPrint('🍎 iOS는 기본 알림으로 처리됨');
      }
    } catch (e) {
      debugPrint('❌ 알람 표시 실패: $e');
      _setMessage('🔔 알람이 울렸습니다! (오류: $e)');
    }
  }

  // BuildContext 설정
  void setContext(BuildContext context) {
    _context = context;
  }

  // BuildContext 가져오기
  BuildContext? _getContext() {
    return _context;
  }

  // 잠금화면 모드 확인
  Future<void> _checkLockScreenMode() async {
    if (!Platform.isAndroid) return;

    try {
      bool isLockScreenMode = await _autoLockScreenChannel.invokeMethod('getLockScreenMode');
      _setLockScreenMode(isLockScreenMode);

      if (isLockScreenMode) {
        _setMessage('🔒 잠금화면 모드로 실행됨\n\n이 화면에서 앱을 사용할 수 있습니다.');
      }
    } catch (e) {
      // 잠금화면 모드 확인 실패시 일반 모드로 처리
      _setLockScreenMode(false);
    }
  }

  // 배터리 최적화 예외 요청 (사용자가 직접 선택할 때만)
  Future<void> requestBatteryOptimizationExemption() async {
    if (!Platform.isAndroid) return;

    try {
      await _autoLockScreenChannel.invokeMethod('requestBatteryOptimizationExemption');
      _setMessage('⚡ 배터리 최적화 예외를 설정하면 잠금화면 기능이 더 안정적으로 동작합니다.');
    } catch (e) {
      _setMessage('배터리 최적화 설정 중 오류: $e');
    }
  }

  // 잠금화면 모드 종료
  Future<void> exitLockScreenMode() async {
    if (!Platform.isAndroid) return;

    try {
      await _autoLockScreenChannel.invokeMethod('exitLockScreenMode');
    } catch (e) {
      _setMessage('잠금화면 모드 종료 중 오류: $e');
    }
  }

  // 기존 호환성을 위한 1분 알람 메서드
  Future<void> scheduleAlarm() async {
    await scheduleAlarmWithDelay(60); // 1분 = 60초
  }

  // 지연 시간을 사용자 친화적 텍스트로 변환
  String _formatDelayTime(int seconds) {
    if (seconds < 60) {
      return '$seconds초';
    } else {
      int minutes = seconds ~/ 60;
      return '$minutes분';
    }
  }

  // 등록된 알람 개수 조회 (UI에서 표시용)
  int getAlarmCount() {
    return state.scheduledAlarms.length;
  }

  // 알람 목록에 추가
  void _addAlarmToList(AlarmInfo alarmInfo) {
    final updatedAlarms = [
      ...state.scheduledAlarms,
      alarmInfo
    ];
    state = state.copyWith(scheduledAlarms: updatedAlarms);
  }

  // 알람 목록에서 제거
  void _removeAlarmFromList(int alarmId) {
    final updatedAlarms = state.scheduledAlarms.where((alarm) => alarm.id != alarmId).toList();
    state = state.copyWith(scheduledAlarms: updatedAlarms);
  }

  // 수동으로 알람 취소
  Future<void> cancelAlarm(int alarmId) async {
    try {
      // 시스템 알림 취소
      await _notificationsPlugin.cancel(alarmId);

      // WorkManager 알람도 취소
      await _autoLockScreenChannel.invokeMethod('cancelWorkManagerAlarm', {
        'alarmId': alarmId,
      });

      // 목록에서 제거
      _removeAlarmFromList(alarmId);

      _setMessage('✅ 알람 #$alarmId이 취소되었습니다.');
    } catch (e) {
      _setMessage('알람 취소 중 오류가 발생했습니다: $e');
    }
  }

  // 모든 알람 취소
  Future<void> cancelAllAlarms() async {
    try {
      // 모든 시스템 알림 취소
      await _notificationsPlugin.cancelAll();

      // 각 WorkManager 알람도 개별 취소
      for (final alarm in state.scheduledAlarms) {
        try {
          await _autoLockScreenChannel.invokeMethod('cancelWorkManagerAlarm', {
            'alarmId': alarm.id,
          });
        } catch (e) {
          debugPrint('WorkManager 알람 ${alarm.id} 취소 실패: $e');
        }
      }

      // 목록 초기화
      state = state.copyWith(scheduledAlarms: []);

      _setMessage('✅ 모든 알람이 취소되었습니다.');
    } catch (e) {
      _setMessage('모든 알람 취소 중 오류가 발생했습니다: $e');
    }
  }

  // 네이티브에서 모드 변경 알림을 받는 리스너 설정
  void _setupMethodChannelListener() {
    _autoLockScreenChannel.setMethodCallHandler((call) async {
      if (call.method == 'onLockScreenModeChanged') {
        bool newMode = call.arguments as bool;
        debugPrint('🔄 Mode changed from native: $newMode');
        _setLockScreenMode(newMode);

        if (newMode) {
          _setMessage('🔒 잠금화면 모드로 실행됨\n\n이 화면에서 앱을 사용할 수 있습니다.');
        } else {
          _setMessage('📱 일반 모드로 실행됨\n\n앱을 종료하고 화면을 껐다 켜보세요.');
        }
      } else if (call.method == 'showAlarmScreen') {
        // 네이티브에서 알람 화면 표시 요청 (즉시 처리)
        final title = call.arguments['title'] ?? 'TODO 알람';
        final message = call.arguments['message'] ?? '알람이 울렸습니다!';
        final alarmId = call.arguments['alarmId'] ?? -1;

        // 알람 중복 실행 방지
        final isProcessed = await _isAlarmProcessed(alarmId);
        if (isProcessed) {
          return;
        }

        await _addProcessedAlarmId(alarmId);

        // 알람 화면 표시
        final context = _getContext();
        if (context != null) {
          context.go('/alarm?title=$title&message=$message');
        }

        // 알람 목록에서 제거
        if (alarmId != -1) {
          _removeAlarmFromList(alarmId);
        }
      }
    });
  }

  // 잠금화면 모드 상태 업데이트
  void _setLockScreenMode(bool isLockScreenMode) {
    state = state.copyWith(isLockScreenMode: isLockScreenMode);
  }

  // dispose 시 리소스 정리
  void dispose() {
    // SharedPreferences를 사용하므로 별도 정리 불필요
    // 정리는 _addProcessedAlarmId에서 자동으로 처리됨
  }
}

// Freezed를 사용한 상태 클래스
@freezed
class HomeViewState with _$HomeViewState {
  const factory HomeViewState({
    required bool isLoading,
    @Default(false) bool isServiceRunning,
    @Default(false) bool isLockScreenMode,
    @Default([]) List<AlarmInfo> scheduledAlarms,
    @Default(false) bool needsPermissionSetup,
  }) = _HomeViewState;
}

@freezed
class AlarmInfo with _$AlarmInfo {
  const factory AlarmInfo({
    required int id,
    required String title,
    required String message,
    required DateTime scheduledTime,
    required int delaySeconds,
  }) = _AlarmInfo;
}
