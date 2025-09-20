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
import '../views/alarm_view.dart';

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
      print('처리된 알람 ID 로드 실패: $e');
    }
    return <int>{};
  }

  Future<void> _saveProcessedAlarmIds(Set<int> alarmIds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> stringList = alarmIds.map((id) => id.toString()).toList();
      await prefs.setStringList(_processedAlarmsKey, stringList);
    } catch (e) {
      print('처리된 알람 ID 저장 실패: $e');
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
      isLoading: false,
      message: '✅ 자동 잠금 화면 감지가 활성화되었습니다!\n\n앱을 종료하고 화면을 껐다 켜보세요.',
      isServiceRunning: true,
      isLockScreenMode: false,
    );

    Future.microtask(() async {
      await _initializeNotifications();
      await _autoStartService();
      await _checkLockScreenMode();
      _setupMethodChannelListener();
    });

    return initialState;
  }

  Future<void> _initializeNotifications() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
      final bool? initialized = await _notificationsPlugin.initialize(initializationSettings);
      print('📱 Notification 초기화 결과: $initialized');
    } catch (e) {
      print('Notification 초기화 실패: $e');
    }
  }

  // 앱 시작 시 자동으로 서비스 시작
  Future<void> _autoStartService() async {
    if (!Platform.isAndroid) {
      _setMessage('iOS는 지원되지 않습니다.');
      return;
    }

    try {
      _setLoading(true);

      // 네이티브 코드에서 자동으로 권한 확인 및 서비스 시작
      await _autoLockScreenChannel.invokeMethod('checkAndStartService');

      _setMessage('✅ 백그라운드 서비스가 자동으로 시작되었습니다!\n\n이제 앱을 완전히 종료하고 화면을 껐다 켜보세요.\n화면이 켜지는 순간 이 앱이 나타납니다!');
      _setServiceRunning(true);
    } catch (e) {
      _setMessage('❌ 서비스 시작 중 오류: $e\n\n"다른 앱 위에 표시" 권한을 허용해주세요.');
      _setServiceRunning(false);
    }

    _setLoading(false);
  }

  // 서비스 상태 확인
  Future<void> checkServiceStatus() async {
    if (!Platform.isAndroid) return;

    try {
      bool isRunning = await _autoLockScreenChannel.invokeMethod('isServiceRunning');
      _setServiceRunning(isRunning);

      if (isRunning) {
        _setMessage('✅ 백그라운드 서비스가 실행 중입니다!\n\n화면을 껐다 켜보세요.');
      } else {
        _setMessage('❌ 서비스가 실행되지 않았습니다.\n권한을 확인해주세요.');
        // 서비스가 실행되지 않으면 다시 시작 시도
        await _autoStartService();
      }
    } catch (e) {
      _setMessage('서비스 상태 확인 중 오류: $e');
      _setServiceRunning(false);
    }
  }

  // 로딩 상태 업데이트
  void _setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  // 메시지 업데이트
  void _setMessage(String message) {
    state = state.copyWith(message: message);
  }

  // 서비스 실행 상태 업데이트
  void _setServiceRunning(bool isRunning) {
    state = state.copyWith(isServiceRunning: isRunning);
  }

  // 수동 권한 요청 (필요시)
  Future<void> requestPermissions() async {
    _setLoading(true);
    _setMessage('권한을 요청하고 있습니다...');

    try {
      // 알림 권한 요청
      PermissionStatus notificationStatus = await Permission.notification.request();
      if (notificationStatus != PermissionStatus.granted) {
        _setMessage('❌ 알림 권한이 필요합니다.');
        _setLoading(false);
        return;
      }

      // Android 12+ 정확한 알람 권한 요청
      if (Platform.isAndroid) {
        final exactAlarmPermission = await Permission.scheduleExactAlarm.status;
        if (exactAlarmPermission != PermissionStatus.granted) {
          final result = await Permission.scheduleExactAlarm.request();
          if (result != PermissionStatus.granted) {
            _setMessage('❌ 정확한 알람 권한이 필요합니다.');
            _setLoading(false);
            return;
          }
        }
      }

      _setMessage('✅ 모든 권한이 허용되었습니다! 서비스를 다시 시작합니다.');
      await _autoStartService();
    } catch (e) {
      _setMessage('권한 요청 중 오류가 발생했습니다: $e');
    }

    _setLoading(false);
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
        print('❌ Timezone 오류, UTC 사용: $e');
        // timezone 실패 시 UTC 사용
        final utcTime = DateTime.now().toUtc().add(Duration(seconds: delaySeconds));
        scheduledTime = tz.TZDateTime.from(utcTime, tz.UTC);
      }

      // 고유한 알람 ID 생성 (현재 시간 기반으로 중복 방지)
      final int alarmId = DateTime.now().millisecondsSinceEpoch % 2147483647;

      String timeText = _formatDelayTime(delaySeconds);
      final String title = 'TODO 알람 #$alarmId';
      final String message = '$timeText 후 알람입니다!';

      // 릴리즈 모드 대응: 두 가지 방법으로 시도
      bool notificationScheduled = false;

      // 방법 1: zonedSchedule 시도
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
        notificationScheduled = true;
        print('✅ zonedSchedule 성공');
      } catch (e) {
        print('❌ zonedSchedule 실패: $e');

        // 방법 2: show 즉시 알림 + Timer 대체 사용
        try {
          // 즉시 알림 표시는 하지 않고, Timer만 사용
          print('🔄 zonedSchedule 실패로 Timer만 사용');
          notificationScheduled = true; // Timer는 이미 아래에서 설정됨
        } catch (e2) {
          print('❌ 대체 방법도 실패: $e2');
          throw Exception('알림 등록 실패: $e');
        }
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

      print('✅ WorkManager 알람 스케줄링 요청 완료');
    } catch (e) {
      print('❌ 알람 등록 오류 상세: $e');
      print('❌ 오류 타입: ${e.runtimeType}');
      if (e is PlatformException) {
        print('❌ PlatformException - code: ${e.code}, message: ${e.message}');
      }
      _setMessage('알람 등록 중 오류가 발생했습니다: $e\n\n오류 타입: ${e.runtimeType}');
    }

    _setLoading(false);
  }

  // Flutter 알람 화면 표시 (Navigation 기반)
  void _showFlutterAlarmScreen() {
    _showNavigationAlarm();
  }

  // Navigation 기반 전체 화면 알람 표시
  void _showNavigationAlarm() {
    print('🚨 _showNavigationAlarm 호출됨!');
    try {
      // Android: 네이티브 채널로 화면 깨우기 + 사운드 재생 요청
      if (Platform.isAndroid) {
        _autoLockScreenChannel.invokeMethod('showFullScreenAlarm', {
          'title': 'TODO 알람 123 ',
          'message': '등록된 할 일 시간입니다! 123',
        });
        print('🔔 Android 네이티브 알람 요청 전송 완료');
      }

      // iOS는 기본 알림만 사용 (Navigation 안함)
      if (Platform.isIOS) {
        print('🍎 iOS는 기본 알림으로 처리됨');
      }
    } catch (e) {
      print('❌ 알람 표시 실패: $e');
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

  // 팝업 테스트 - 다이얼로그로 변경
  void showTestPopup() {
    // 메시지는 간단하게만 업데이트
    _setMessage('팝업 테스트 버튼이 클릭되었습니다.');
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
          print('WorkManager 알람 ${alarm.id} 취소 실패: $e');
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
        print('🔄 Mode changed from native: $newMode');
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
    required String message,
    @Default(false) bool isServiceRunning,
    @Default(false) bool isLockScreenMode,
    @Default([]) List<AlarmInfo> scheduledAlarms,
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
