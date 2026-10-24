import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../models/task_item.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../widgets/header_date_time.dart';

class PlannerTab extends StatefulWidget {
  const PlannerTab({super.key});

  @override
  State<PlannerTab> createState() => _PlannerTabState();
}

class _PlannerTabState extends State<PlannerTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<TaskItem> _tasks = [];
  bool _isLoading = true;
  final TextEditingController _inputController = TextEditingController();
  late DateTime _selectedDate;
  TimeOfDay? _selectedTime;
  int? _selectedAlarmMinutes = 5; // 기본값: 5분 전

  static const List<({int? minutes, String label})> _alarmOptions = [
    (minutes: 0, label: '정시 (0분 전)'),
    (minutes: 5, label: '5분 전 (기본)'),
    (minutes: 10, label: '10분 전'),
    (minutes: 30, label: '30분 전'),
    (minutes: 60, label: '1시간 전'),
    (minutes: null, label: '알람 끔'),
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = _defaultDisplayDate;
    _loadTasks();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  String _formatDateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _formatShortDate(DateTime d) {
    final now = DateTime.now();
    final todayKey = _formatDateKey(now);
    final tomorrowKey = _formatDateKey(now.add(const Duration(days: 1)));
    final thisKey = _formatDateKey(d);

    const days = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = days[d.weekday - 1];

    if (thisKey == todayKey) {
      return '오늘: ${d.month}.${d.day} ($weekday)';
    } else if (thisKey == tomorrowKey) {
      return '내일: ${d.month}.${d.day} ($weekday)';
    }
    return '${d.month}.${d.day} ($weekday)';
  }

  String _formatTaskDate(String forDate) {
    if (forDate.isEmpty) return '';
    final parts = forDate.split('-');
    if (parts.length < 3) return forDate;
    final y = int.tryParse(parts[0]) ?? 2026;
    final m = int.tryParse(parts[1]) ?? 1;
    final d = int.tryParse(parts[2]) ?? 1;
    final dt = DateTime(y, m, d);

    final now = DateTime.now();
    final todayKey = _formatDateKey(now);
    final tomorrowKey = _formatDateKey(now.add(const Duration(days: 1)));

    const days = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = days[dt.weekday - 1];

    if (forDate == todayKey) {
      return '오늘 $m.$d ($weekday)';
    } else if (forDate == tomorrowKey) {
      return '내일 $m.$d ($weekday)';
    }
    return '$m.$d ($weekday)';
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final period = time.hour < 12 ? '오전' : '오후';
    final hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final min = time.minute.toString().padLeft(2, '0');
    return '$period $hour:$min';
  }

  String _getAlarmLabel(int? minutes) {
    if (minutes == null) return '알람 끔';
    if (minutes == 0) return '정시 알람';
    if (minutes == 60) return '1시간 전 알람';
    return '$minutes분 전 알람';
  }

  DateTime get _defaultDisplayDate {
    final now = DateTime.now();
    // 밤 9시 이후 또는 새벽에는 내일 아침/낮 계획을 세우는 경우가 많고, 낮에는 오늘 당일 일정을 주로 등록
    return (now.hour >= 21 || now.hour < 5) ? now.add(const Duration(days: 1)) : now;
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    final all = await StorageService.loadTasks();
    if (!mounted) return;

    final todayKey = _formatDateKey(DateTime.now());

    setState(() {
      // 오늘 이후 일정 또는 아직 완료되지 않은 일정 불러오기
      _tasks = all.where((t) {
        if (t.forDate.isEmpty) return true;
        return t.forDate.compareTo(todayKey) >= 0 || !t.isCompleted;
      }).toList();

      // 날짜 및 시간 순 정렬
      _tasks.sort((a, b) {
        final dateCmp = a.forDate.compareTo(b.forDate);
        if (dateCmp != 0) return dateCmp;
        final aTime = a.time ?? '99:99';
        final bTime = b.time ?? '99:99';
        return aTime.compareTo(bTime);
      });

      _isLoading = false;
    });

    // 미완료 일정들의 알람 예약 동기화
    NotificationService.rescheduleAllTaskAlarms(all);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
      helpText: '일정 날짜 선택',
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 9, minute: 0),
      helpText: '일정 시간 선택 (선택사항)',
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _selectedAlarmMinutes ??= 5;
      });
    }
  }

  void _showAlarmPickerModal({
    required int? currentMinutes,
    required void Function(int? selected) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgDeep,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        bottom: true,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.inkLine,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '🔔 알람 시점 선택',
              style: GoogleFonts.gowunDodum(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '일정 시작 전 마음을 정돈할 수 있도록 One-Beep 알림을 보냅니다.',
              style: GoogleFonts.gowunDodum(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 14),
            ..._alarmOptions.map((opt) {
              final isSelected = currentMinutes == opt.minutes;
              return ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                title: Text(
                  opt.label,
                  style: GoogleFonts.gowunDodum(
                    fontSize: 13.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppColors.accentBrass : AppColors.textPrimary,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check, size: 18, color: AppColors.accentBrass)
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  onSelected(opt.minutes);
                },
              );
            }),
          ],
        ),
      ),
    ),
  );
}

  Future<void> _addTask() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    final targetDateKey = _formatDateKey(_selectedDate);
    final timeStr = _selectedTime != null ? _formatTimeOfDay(_selectedTime!) : null;
    final alarmMin = _selectedTime != null ? _selectedAlarmMinutes : null;

    if (alarmMin != null && !await NotificationService.requestNotificationPermission()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('일정 알림을 사용하려면 브라우저 알림 권한을 허용해 주세요.')),
        );
      }
      return;
    }

    final newItem = await StorageService.addTask(
      text,
      targetDateKey,
      time: timeStr,
      alarmMinutesBefore: alarmMin,
    );

    if (alarmMin != null) {
      await NotificationService.scheduleTaskAlarm(newItem);
    }

    final dateLabel = _formatShortDate(_selectedDate);
    final feedbackMsg = (alarmMin != null && timeStr != null)
        ? '🔔 [$dateLabel $timeStr] ${alarmMin == 0 ? "정시" : "$alarmMin분 전"} 알림이 예약되었습니다 🌿'
        : '📝 [$dateLabel] 일정이 등록되었습니다 🌿';

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            feedbackMsg,
            style: GoogleFonts.gowunDodum(fontSize: 12.5, color: AppColors.textPrimary),
          ),
          backgroundColor: AppColors.bgPanel,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 2500),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: AppColors.inkLine),
          ),
        ),
      );
    }

    _inputController.clear();
    setState(() {
      _selectedTime = null;
      _selectedAlarmMinutes = 5;
    });
    await _loadTasks();
  }

  Future<void> _toggleTask(String id) async {
    await StorageService.toggleTask(id);
    final task = _tasks.firstWhere((t) => t.id == id, orElse: () => _tasks.first);
    if (!task.isCompleted) {
      await NotificationService.cancelTaskAlarm(id);
    }
    await _loadTasks();
  }

  Future<void> _changeTaskAlarm(TaskItem task, int? newAlarmMinutes) async {
    if (newAlarmMinutes != null &&
        !await NotificationService.requestNotificationPermission()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('일정 알림을 사용하려면 브라우저 알림 권한을 허용해 주세요.')),
        );
      }
      return;
    }
    final updated = await StorageService.updateTaskAlarm(task.id, newAlarmMinutes);
    if (updated != null) {
      if (newAlarmMinutes != null) {
        await NotificationService.scheduleTaskAlarm(updated);
      } else {
        await NotificationService.cancelTaskAlarm(updated.id);
      }
    }
    await _loadTasks();
  }

  Future<void> _deleteTask(String id) async {
    await NotificationService.cancelTaskAlarm(id);
    await StorageService.deleteTask(id);
    await _loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final completedCount = _tasks.where((t) => t.isCompleted).length;
    final totalCount = _tasks.length;

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 768;
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 40 : 20,
                vertical: isDesktop ? 24 : 16,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isDesktop ? 860 : 540),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 16),
                      _buildBrainDumpCard(),
                      const SizedBox(height: 16),
                      _buildAddInput(),
                      const SizedBox(height: 16),
                      if (_isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: CircularProgressIndicator(color: AppColors.accentBrass),
                          ),
                        )
                      else if (_tasks.isEmpty)
                        _buildEmptyState()
                      else ...[
                        _buildProgressBanner(completedCount, totalCount),
                        const SizedBox(height: 12),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _tasks.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (ctx, i) => _buildTaskItem(_tasks[i]),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(bottom: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.inkLine, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. 다음 일정 제목 (가운데 정렬)
          Center(
            child: Text(
              '다음 일정',
              style: GoogleFonts.gowunDodum(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.accentNavy,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // 2. 첫 화면과 동일한 위치에 날짜, 시각 표시
          const HeaderDateTime(),
        ],
      ),
    );
  }

  Widget _buildBrainDumpCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgPanel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.inkLine),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🌙', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '수면 전 마음 비우기 (Brain Dump)',
                  style: GoogleFonts.gowunDodum(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '챙겨야 할 일정을 간단히 적어 두세요. 편안한 밤을 맞이할 수 있습니다.',
                  style: GoogleFonts.gowunDodum(fontSize: 11.5, color: AppColors.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddInput() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final isTodaySelected = _formatDateKey(_selectedDate) == _formatDateKey(today);
    final isTomorrowSelected = _formatDateKey(_selectedDate) == _formatDateKey(tomorrow);
    final isCustomDate = !isTodaySelected && !isTomorrowSelected;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accentBrass.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 상단: 날짜 선택 (오늘 / 내일 / 달력 세그먼트)
          Row(
            children: [
              // 오늘 버튼
              InkWell(
                onTap: () => setState(() => _selectedDate = today),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: isTodaySelected ? AppColors.accentBrass.withValues(alpha: 0.18) : AppColors.bgPanel2,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isTodaySelected ? AppColors.accentBrass : AppColors.inkLineLight,
                      width: isTodaySelected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    '오늘 (${today.month}.${today.day})',
                    style: GoogleFonts.gowunDodum(
                      fontSize: 11.5,
                      fontWeight: isTodaySelected ? FontWeight.bold : FontWeight.normal,
                      color: isTodaySelected ? AppColors.accentBrass : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // 내일 버튼
              InkWell(
                onTap: () => setState(() => _selectedDate = tomorrow),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: isTomorrowSelected ? AppColors.accentJade.withValues(alpha: 0.18) : AppColors.bgPanel2,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isTomorrowSelected ? AppColors.accentJade : AppColors.inkLineLight,
                      width: isTomorrowSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    '내일 (${tomorrow.month}.${tomorrow.day})',
                    style: GoogleFonts.gowunDodum(
                      fontSize: 11.5,
                      fontWeight: isTomorrowSelected ? FontWeight.bold : FontWeight.normal,
                      color: isTomorrowSelected ? AppColors.accentJade : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // 달력 선택 버튼
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: isCustomDate ? AppColors.accentNavy.withValues(alpha: 0.15) : AppColors.bgPanel2,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isCustomDate ? AppColors.accentNavy : AppColors.inkLineLight,
                      width: isCustomDate ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_month,
                        size: 13,
                        color: isCustomDate ? AppColors.accentNavy : AppColors.textDim,
                      ),
                      if (isCustomDate) ...[
                        const SizedBox(width: 4),
                        Text(
                          '${_selectedDate.month}.${_selectedDate.day}',
                          style: GoogleFonts.gowunDodum(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accentNavy,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 2. 중간: 시간 선택 및 알람 시점 선택
          Row(
            children: [
              // 시간 선택
              InkWell(
                onTap: _pickTime,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _selectedTime != null ? AppColors.accentBrass.withValues(alpha: 0.12) : AppColors.bgPanel2,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _selectedTime != null ? AppColors.accentBrass : AppColors.inkLineLight,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 13,
                        color: _selectedTime != null ? AppColors.accentBrass : AppColors.textMuted,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _selectedTime != null ? _formatTimeOfDay(_selectedTime!) : '시간 선택 (선택사항)',
                        style: GoogleFonts.gowunDodum(
                          fontSize: 11.5,
                          color: _selectedTime != null ? AppColors.accentBrass : AppColors.textMuted,
                          fontWeight: _selectedTime != null ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      if (_selectedTime != null) ...[
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () => setState(() => _selectedTime = null),
                          child: const Icon(Icons.close, size: 13, color: AppColors.accentBrass),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // 알람 시점 선택
              if (_selectedTime != null) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _showAlarmPickerModal(
                    currentMinutes: _selectedAlarmMinutes,
                    onSelected: (m) => setState(() => _selectedAlarmMinutes = m),
                  ),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _selectedAlarmMinutes != null
                          ? AppColors.accentJade.withValues(alpha: 0.12)
                          : AppColors.bgPanel2,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _selectedAlarmMinutes != null ? AppColors.accentJade : AppColors.inkLineLight,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _selectedAlarmMinutes != null ? Icons.notifications_active : Icons.notifications_off_outlined,
                          size: 13,
                          color: _selectedAlarmMinutes != null ? AppColors.accentJade : AppColors.textMuted,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _getAlarmLabel(_selectedAlarmMinutes),
                          style: GoogleFonts.gowunDodum(
                            fontSize: 11.5,
                            color: _selectedAlarmMinutes != null ? AppColors.accentJade : AppColors.textMuted,
                            fontWeight: _selectedAlarmMinutes != null ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.arrow_drop_down,
                          size: 15,
                          color: _selectedAlarmMinutes != null ? AppColors.accentJade : AppColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),

          // 3. 하단: 일정 내용 입력 및 추가 버튼
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.bgPanel2,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.inkLineLight),
                  ),
                  child: TextField(
                    controller: _inputController,
                    onSubmitted: (_) => _addTask(),
                    style: GoogleFonts.gowunDodum(fontSize: 13.5),
                    decoration: const InputDecoration(
                      hintText: '다음 일정을 적어보세요',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _addTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentBrass,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: Text(
                  '추가',
                  style: GoogleFonts.gowunDodum(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBanner(int completed, int total) {
    final isAllDone = total > 0 && completed == total;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isAllDone ? AppColors.accentJade.withValues(alpha: 0.1) : AppColors.bgPanel2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isAllDone ? AppColors.accentJade : AppColors.inkLine),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isAllDone ? '✨ 모든 일정이 완료되었습니다. 편안히 쉬세요!' : '다음 일정 ($completed/$total 완료)',
            style: GoogleFonts.gowunDodum(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isAllDone ? AppColors.accentJade : AppColors.textPrimary,
            ),
          ),
          Text(
            '${((total > 0 ? completed / total : 0) * 100).round()}%',
            style: GoogleFonts.gowunDodum(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.accentBrass,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(TaskItem task) {
    final hasTime = task.time != null && task.time!.isNotEmpty;
    final dateStr = _formatTaskDate(task.forDate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.bgPanel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: task.isCompleted ? AppColors.inkLine : AppColors.accentBrass.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: SizedBox(
              width: 22,
              height: 22,
              child: Checkbox(
                value: task.isCompleted,
                onChanged: (_) => _toggleTask(task.id),
                activeColor: AppColors.accentJade,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (dateStr.isNotEmpty || hasTime) ...[
                  Wrap(
                    spacing: 5,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // 1. 날짜 및 요일 배지 (시간 앞)
                      if (dateStr.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.bgPanel2,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.inkLineLight),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.event_outlined, size: 11, color: AppColors.textSecondary),
                              const SizedBox(width: 3),
                              Text(
                                dateStr,
                                style: GoogleFonts.gowunDodum(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // 2. 시간 배지
                      if (hasTime)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accentBrass.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.access_time, size: 11, color: AppColors.accentBrass),
                              const SizedBox(width: 3),
                              Text(
                                task.time!,
                                style: GoogleFonts.gowunDodum(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.accentBrass,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // 3. 알람 설정 배지
                      if (hasTime)
                        InkWell(
                          onTap: () => _showAlarmPickerModal(
                            currentMinutes: task.alarmMinutesBefore,
                            onSelected: (m) => _changeTaskAlarm(task, m),
                          ),
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: task.hasAlarm ? AppColors.accentJade.withValues(alpha: 0.12) : AppColors.bgPanel2,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: task.hasAlarm ? AppColors.accentJade.withValues(alpha: 0.3) : AppColors.inkLine,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  task.hasAlarm ? Icons.notifications_active : Icons.notifications_off_outlined,
                                  size: 10,
                                  color: task.hasAlarm ? AppColors.accentJade : AppColors.textDim,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  task.hasAlarm ? task.alarmLabel : '알람끔',
                                  style: GoogleFonts.gowunDodum(
                                    fontSize: 10,
                                    fontWeight: task.hasAlarm ? FontWeight.bold : FontWeight.normal,
                                    color: task.hasAlarm ? AppColors.accentJade : AppColors.textDim,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                ],
                Text(
                  task.title,
                  style: GoogleFonts.gowunDodum(
                    fontSize: 13.5,
                    color: task.isCompleted ? AppColors.textDim : AppColors.textPrimary,
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: AppColors.textDim),
            onPressed: () => _deleteTask(task.id),
            tooltip: '삭제',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            splashRadius: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(30),
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: AppColors.bgPanel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.inkLine),
      ),
      child: Column(
        children: [
          const Text('📝', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 12),
          Text(
            '등록된 일정이 없습니다.',
            style: GoogleFonts.gowunDodum(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            '챙겨야 할 일정을 적어두면\n잠자리가 한결 편안해집니다.',
            textAlign: TextAlign.center,
            style: GoogleFonts.gowunDodum(fontSize: 12, color: AppColors.textMuted, height: 1.5),
          ),
        ],
      ),
    );
  }
}