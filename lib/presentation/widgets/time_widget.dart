import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ideamemo/core/utils/font_size_manager.dart';
import 'dart:async';

/// 날짜/시간 표시 위젯 - 분 단위로만 업데이트하여 성능 최적화
class TimeWidget extends StatefulWidget {
  final TextStyle? timeStyle;
  final TextStyle? dateStyle;
  final bool showDate;

  const TimeWidget({
    super.key,
    this.timeStyle,
    this.dateStyle,
    this.showDate = false,
  });

  @override
  State<TimeWidget> createState() => _TimeWidgetState();
}

class _TimeWidgetState extends State<TimeWidget> {
  Timer? _timer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    // 현재 시간으로 즉시 초기화 (초는 무시하고 분 단위로 표시)
    _currentTime = DateTime.now();

    // 현재 시간의 다음 분까지의 초를 계산
    final now = DateTime.now();
    final nextMinute = DateTime(now.year, now.month, now.day, now.hour, now.minute + 1);
    final initialDelay = nextMinute.difference(now);

    // 첫 번째 업데이트를 다음 분에 맞춰서 실행
    Timer(initialDelay, () {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });

        // 그 이후부터는 1분마다 정확히 업데이트
        _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
          if (mounted) {
            setState(() {
              _currentTime = DateTime.now();
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showDate) {
      // 날짜와 시간을 모두 표시
      return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            DateFormat('yyyy년 MM월 dd일').format(_currentTime),
            style: widget.dateStyle,
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('HH:mm').format(_currentTime),
            style: widget.timeStyle,
          ),
        ],
      );
    } else {
      // 시간만 표시
      return Text(
        DateFormat('HH:mm').format(_currentTime),
        style: widget.timeStyle,
      );
    }
  }
}
