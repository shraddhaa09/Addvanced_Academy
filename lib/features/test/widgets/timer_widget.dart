// lib/features/tests/widgets/timer_widget.dart

import 'dart:async';
import 'package:flutter/material.dart';

// ── Theme Tokens (same as your app) ───────────────────────────
const Color _primary = Color(0xFF6C5CE7);
const Color _danger  = Color(0xFFE74C3C);
const Color _bgLight = Color(0xFFF4F3FB);
const Color _textDark = Color(0xFF1A1A2E);
const Color _textMuted = Color(0xFF9B9BB4);

class TimerWidget extends StatefulWidget {
  final int totalSeconds;
  final VoidCallback onTimeUp;

  const TimerWidget({
    super.key,
    required this.totalSeconds,
    required this.onTimeUp,
  });

  @override
  State<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget> {
  late int _secondsLeft;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.totalSeconds;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 0) {
        timer.cancel();
        widget.onTimeUp();
      } else {
        setState(() {
          _secondsLeft--;
        });
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDanger = _secondsLeft <= 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDanger ? _danger.withAlpha(25) : _bgLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDanger ? _danger : Colors.transparent,
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_rounded,
            size: 18,
            color: isDanger ? _danger : _primary,
          ),
          const SizedBox(width: 6),
          Text(
            _formatTime(_secondsLeft),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDanger ? _danger : _textDark,
            ),
          ),
        ],
      ),
    );
  }
}