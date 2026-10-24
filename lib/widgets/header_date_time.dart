import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

/// 첫 화면과 동일한 스타일의 상단 실시간 일시(날짜 및 시각) 표시 위젯
class HeaderDateTime extends StatefulWidget {
  final bool isNarrow;

  const HeaderDateTime({
    super.key,
    this.isNarrow = false,
  });

  @override
  State<HeaderDateTime> createState() => _HeaderDateTimeState();
}

class _HeaderDateTimeState extends State<HeaderDateTime> {
  DateTime _currentTime = DateTime.now();
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  String _formatDisplayDate(DateTime d) {
    const days = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = days[d.weekday - 1];
    return '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')} ($weekday)';
  }

  String _formatDisplayTime(DateTime d) {
    final period = d.hour < 12 ? '오전' : '오후';
    final hour = d.hour == 0 ? 12 : (d.hour > 12 ? d.hour - 12 : d.hour);
    final min = d.minute.toString().padLeft(2, '0');
    final sec = d.second.toString().padLeft(2, '0');
    return '$period $hour:$min:$sec';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${_formatDisplayDate(_currentTime)}   ${_formatDisplayTime(_currentTime)}',
          style: GoogleFonts.gowunDodum(
            fontSize: widget.isNarrow ? 12 : 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}
