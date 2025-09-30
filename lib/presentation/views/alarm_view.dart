import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';
import 'package:ideamemo/core/utils/font_size_manager.dart';

class AlarmView extends StatefulWidget {
  final String title;
  final String message;
  final VoidCallback? onDismiss;
  final VoidCallback? onSnooze;

  const AlarmView({
    super.key,
    this.title = 'TODO 알람',
    this.message = '등록된 할 일 시간입니다!',
    this.onDismiss,
    this.onSnooze,
  });

  @override
  State<AlarmView> createState() => _AlarmViewState();
}

class _AlarmViewState extends State<AlarmView> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _shakeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shakeAnimation;

  String _alarmTitle = 'TODO 알람';
  String _alarmMessage = '등록된 할 일 시간입니다!';
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();

    // 펄스 애니메이션 (알람 아이콘)
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // 흔들림 애니메이션 (전체 화면)
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 10,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));

    // 애니메이션 시작 (떨림 애니메이션 제거)
    _pulseController.repeat(reverse: true);
    // _shakeController.repeat(reverse: true); // 떨림 애니메이션 제거

    // 네이티브에서 알람 데이터 가져오기 (Navigation에서는 widget으로 전달받음)
    _initializeAlarmData();

    // 알람 사운드 재생
    _playAlarmSound();

    // 진동
    _vibrate();
  }

  @override
  void dispose() {
    _soundTimer?.cancel();
    _pulseController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  // Navigation 방식에서는 widget으로 데이터를 받음
  void _initializeAlarmData() {
    setState(() {
      _alarmTitle = widget.title;
      _alarmMessage = widget.message;
      _isPlaying = true;
    });
  }

  Timer? _soundTimer;

  // 기본 시스템 사운드 재생
  Future<void> _playAlarmSound() async {
    try {
      // 즉시 사운드 재생
      SystemSound.play(SystemSoundType.alert);

      // 반복 재생을 위해 Timer 사용 (1초마다)
      _soundTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_isPlaying && mounted) {
          SystemSound.play(SystemSoundType.alert);
          // 진동도 함께
          HapticFeedback.heavyImpact();
        } else {
          timer.cancel();
        }
      });

      debugPrint('🔊 시스템 알람 사운드 재생 시작');
    } catch (e) {
      debugPrint('알람 사운드 재생 실패: $e');
    }
  }

  // 사운드 토글 (간단하게 상태만 변경)
  void _toggleAlarmSound() {
    setState(() {
      _isPlaying = !_isPlaying;
    });

    if (_isPlaying) {
      _playAlarmSound();
    } else {
      _soundTimer?.cancel();
    }
  }

  Future<void> _vibrate() async {
    try {
      // 진동 패턴 (0.5초 진동, 0.2초 멈춤, 반복)
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          HapticFeedback.heavyImpact();
        }
      });
    } catch (e) {
      debugPrint('진동 실행 실패: $e');
    }
  }

  void _dismissAlarm() async {
    // 사운드 중지
    setState(() {
      _isPlaying = false;
    });
    _soundTimer?.cancel();

    // Android: 네이티브 사운드도 정지
    if (Platform.isAndroid) {
      try {
        await MethodChannel('auto_lockscreen_channel').invokeMethod('stopAlarmSound');
      } catch (e) {
        debugPrint('네이티브 사운드 정지 실패: $e');
      }
    }

    _pulseController.stop();
    // _shakeController.stop(); // 떨림 애니메이션 제거
    widget.onDismiss?.call();
  }

  void _snoozeAlarm() async {
    // 사운드 중지
    setState(() {
      _isPlaying = false;
    });
    _soundTimer?.cancel();

    // Android: 네이티브 사운드도 정지
    if (Platform.isAndroid) {
      try {
        await MethodChannel('auto_lockscreen_channel').invokeMethod('stopAlarmSound');
      } catch (e) {
        debugPrint('네이티브 사운드 정지 실패: $e');
      }
    }

    _pulseController.stop();
    // _shakeController.stop(); // 떨림 애니메이션 제거
    widget.onSnooze?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade900,
      // 전체 화면으로 설정 (상태바, 네비게이션바 숨김)
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.red.shade900,
              Colors.red.shade700,
              Colors.orange.shade600,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 현재 시간
              Text(
                _getCurrentTime(),
                style: TextStyle(
                  fontSize: AppFontSizes.clockTimeSize,
                  color: Colors.white70,
                  fontWeight: FontWeight.w300,
                ),
              ),

              const SizedBox(height: 40),

              // 알람 아이콘 (펄스 애니메이션)
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.2),
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                      ),
                      child: const Icon(
                        Icons.alarm,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),

              // 알람 제목
              Text(
                _alarmTitle,
                style: TextStyle(
                  fontSize: FontSizeManager.getScaledSize(32),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              // 알람 메시지
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  _alarmMessage,
                  style: TextStyle(
                    fontSize: AppFontSizes.headlineTextSize,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 60),

              // 버튼들
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 다시 알림 버튼
                  _buildActionButton(
                    icon: Icons.snooze,
                    label: '5분 후',
                    onPressed: _snoozeAlarm,
                    backgroundColor: Colors.orange,
                  ),

                  // 해제 버튼
                  _buildActionButton(
                    icon: Icons.alarm_off,
                    label: '해제',
                    onPressed: _dismissAlarm,
                    backgroundColor: Colors.green,
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // 사운드 토글 버튼
              TextButton.icon(
                onPressed: _toggleAlarmSound,
                icon: Icon(
                  _isPlaying ? Icons.volume_off : Icons.volume_up,
                  color: Colors.white70,
                ),
                label: Text(
                  _isPlaying ? '소리 끄기' : '소리 켜기',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: AppFontSizes.titleTextSize,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color backgroundColor,
  }) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: backgroundColor,
            boxShadow: [
              BoxShadow(
                color: backgroundColor.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(
              icon,
              size: 40,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: AppFontSizes.buttonTextSize,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }
}
