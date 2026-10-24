import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/task_item.dart';
import '../models/quote.dart';
import 'sound_service.dart';
import 'storage_service.dart';
import 'web_notification.dart';

/// audistine 웹/모바일 환경 통합 안전 알림 서비스
class NotificationService {
  static const int dailyNotificationId = 1;
  static const int testNotificationId = 999;
  static final RegExp _alphabetRegex = RegExp(r'[a-zA-Z]');

  static Timer? _monitoringTimer;
  static bool _isMonitoring = false;
  static final Map<String, Timer> _activeTaskTimers = {};

  static Future<void> initTimeZone() async {}

  static Future<void> initNotifications() async {
    await initPlatformNotifications();
    startMonitoring();
  }

  static Future<bool> requestNotificationPermission() async {
    return await requestPlatformNotificationPermission();
  }

  static Future<void> requestPermissions() async {
    await requestPlatformNotificationPermission();
  }

  static Future<bool?> requestExactAlarmPermission() async => true;

  /// 백그라운드 / 포그라운드 정기 모니터링 시작 (15초 간격으로 명언 및 일정 알림 점검)
  static void startMonitoring() {
    // 웹은 index.html의 LocalStorage 워치독이 유일한 스케줄러로 동작한다.
    // Dart 타이머와 함께 실행하면 동일 알림이 중복 표시될 수 있다.
    if (kIsWeb) return;
    if (_isMonitoring && _monitoringTimer?.isActive == true) return;
    _isMonitoring = true;

    // 기동 즉시 첫 확인
    _checkAndTriggerDailyQuote();
    _checkAndTriggerTaskAlarms();

    // 15초마다 시간 비교 루프
    _monitoringTimer?.cancel();
    _monitoringTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _checkAndTriggerDailyQuote();
      _checkAndTriggerTaskAlarms();
    });
    debugPrint('[NotificationService] audistine 알림 모니터링 시작 (15초 주기)');
  }

  /// 매일 명언 알림 시각 설정 및 스케줄링
  static Timer? _directDailyTimer;

  /// 매일 명언 알림 시각 설정 및 스케줄링 (오늘 5분 뒤라도 바로 발송 가능하도록 타이머 및 슬롯 구성)
  static Future<bool> scheduleDailyNotification(
    TimeOfDay time, {
    String? previewText,
    bool forceEnable = false,
  }) async {
    // 브라우저 권한은 실제 사용자 동작에서 별도로 요청해야 한다.
    // 1. 시간 및 활성화 상태 로컬 저장
    if (forceEnable) {
      await StorageService.setDailyNotificationEnabled(true);
    }
    await StorageService.saveNotificationTime(time);

    // 2. 네이티브 타이머만 앱이 실행되는 동안 사용한다. 웹은 JS 워치독이 담당한다.
    if (!kIsWeb) {
      final now = DateTime.now();
      var targetDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
        0,
      );
      if (!targetDateTime.isAfter(now)) {
        targetDateTime = targetDateTime.add(const Duration(days: 1));
      }
      final delay = targetDateTime.difference(now);
      debugPrint(
        '[NotificationService] 일일 알림 스케줄: $targetDateTime (${delay.inMinutes}분 ${delay.inSeconds % 60}초 후)',
      );

      _directDailyTimer?.cancel();
      _directDailyTimer = Timer(delay, () async {
        await _fireDailyQuoteNotification();
        _setupRecurringDailyTimer(time);
      });
    }

    // 4. 슬롯 키 초기화 (새로 설정한 시각에 발송될 수 있도록 기존 슬롯 락 해제)
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('audistine_last_daily_slot');
    syncLastDailySlotToLocalStorage('');
    await StorageService.setLastDailyNotifiedDate('');
    syncLastNotifiedDateToLocalStorage(prefix: 'audistine_', dateStr: '');

    // 5. 모바일 네이티브 스케줄러 등록 (스마트폰 백그라운드 및 기기 꺼짐 후 부팅 시에도 작동)
    await scheduleNativeDailyNotification(
      id: dailyNotificationId,
      title: '오늘의 명언이 도착했습니다.',
      body: previewText ?? 'audistine 오늘의 명언을 확인해 보세요.',
      hour: time.hour,
      minute: time.minute,
    );

    // 6. 웹 LocalStorage 동기화 (JS 백그라운드 스케줄러 연동용)
    syncNotificationConfigToLocalStorage(
      prefix: 'audistine_',
      hour: time.hour,
      minute: time.minute,
      enabled: true,
      previewText: previewText,
    );
    final serverPushReady = await _syncDailyPushConfig(
      time.hour,
      time.minute,
      true,
    );

    // 7. 모니터링 루프 가동
    startMonitoring();

    debugPrint(
      '[NotificationService] audistine 매일 알림 시각 설정 완료: ${time.hour}:${time.minute}',
    );
    return serverPushReady;
  }

  static void _setupRecurringDailyTimer(TimeOfDay time) {
    final now = DateTime.now();
    var next = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
      0,
    ).add(const Duration(days: 1));
    final delay = next.difference(now);
    _directDailyTimer = Timer(delay, () async {
      await _fireDailyQuoteNotification();
      _setupRecurringDailyTimer(time);
    });
  }

  /// 일일 알림 해제
  static Future<void> cancelDailyNotification() async {
    await StorageService.setDailyNotificationEnabled(false);
    await cancelNativeNotification(dailyNotificationId);
    syncNotificationConfigToLocalStorage(
      prefix: 'audistine_',
      hour: 9,
      minute: 0,
      enabled: false,
    );
    await _syncDailyPushConfig(9, 0, false);
    debugPrint('[NotificationService] audistine 일일 알림 해제');
  }

  static Future<bool> _syncDailyPushConfig(
    int hour,
    int minute,
    bool enabled,
  ) async {
    if (!kIsWeb) return true;
    final prefs = await SharedPreferences.getInstance();
    final seed = await QuoteRepository.getOrCreateDeviceSeed(prefs);
    return syncDailyPushConfig(hour, minute, enabled, seed);
  }

  /// 매 15초마다 호출되어 명언 알림 발송 조건 충족 여부 점검
  static Future<void> _checkAndTriggerDailyQuote() async {
    final isDailyEnabled = await StorageService.isDailyNotificationEnabled();
    if (!isDailyEnabled) return;

    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final targetTime = await StorageService.loadNotificationTime();
    final slotKey = '${todayStr}_${targetTime.hour}_${targetTime.minute}';

    final prefs = await SharedPreferences.getInstance();
    final lastSlot = prefs.getString('audistine_last_daily_slot') ?? '';

    // 오늘 설정된 목표 슬롯에 아직 발송되지 않은 상태에서 목표 시각에 도달했는지 확인
    if (lastSlot != slotKey) {
      final nowMinutes = now.hour * 60 + now.minute;
      final targetMinutes = targetTime.hour * 60 + targetTime.minute;
      final diffMinutes = nowMinutes - targetMinutes;

      // 정각이거나 방금 지난 5분 이내라면 발송 (오늘 5분 뒤로 설정한 경우에도 즉각 도달 시 발송!)
      if (diffMinutes >= 0 && diffMinutes <= 5) {
        debugPrint(
          '[NotificationService] audistine 오늘의 명언 발송 조건 충족 ($slotKey)',
        );
        await prefs.setString('audistine_last_daily_slot', slotKey);
        await StorageService.setLastDailyNotifiedDate(todayStr);
        syncLastNotifiedDateToLocalStorage(
          prefix: 'audistine_',
          dateStr: todayStr,
        );
        syncLastDailySlotToLocalStorage(slotKey);
        await _fireDailyQuoteNotification();
      }
    }
  }

  /// 오늘의 명언 실제 알림 발송 및 싱잉볼 종소리 재생
  static Future<void> _fireDailyQuoteNotification() async {
    try {
      final quotes = await QuoteRepository.loadQuotes();
      final prefs = await SharedPreferences.getInstance();
      final seed = await QuoteRepository.getOrCreateDeviceSeed(prefs);
      final quote = QuoteRepository.getDailyQuote(quotes, DateTime.now(), seed);

      const title = '오늘의 명언이 도착했습니다.';
      String body = quote.translation.isNotEmpty
          ? quote.translation
          : quote.original;
      if (body.isEmpty) {
        body = quote.english;
      }
      if (quote.source.isNotEmpty) {
        body += ' — ${quote.source}';
      }

      await showPlatformNotification(
        title: title,
        body: body,
        icon: 'icons/Icon-192.png',
      );

      try {
        await SoundService.playChime();
      } catch (soundErr) {
        debugPrint('[NotificationService] 사운드 재생 에러: $soundErr');
      }
    } catch (e, st) {
      debugPrint('[NotificationService] 명언 알림 발송 중 에러: $e\n$st');
    }
  }

  // ==========================================
  // 다음 일정 알림 (Task Alarm)
  // ==========================================

  /// TaskItem의 알람 예정 DateTime 계산
  static DateTime? getTaskAlarmDateTime(TaskItem task) {
    if (task.isCompleted ||
        task.alarmMinutesBefore == null ||
        task.time == null ||
        task.time!.trim().isEmpty) {
      return null;
    }
    final dateParts = task.forDate.split('-');
    if (dateParts.length < 3) return null;
    final year = int.tryParse(dateParts[0]);
    final month = int.tryParse(dateParts[1]);
    final day = int.tryParse(dateParts[2]);
    if (year == null || month == null || day == null) return null;

    final parsed = parseTimeString(task.time);
    if (parsed == null) return null;

    final taskTime = DateTime(year, month, day, parsed.hour, parsed.minute);
    return taskTime.subtract(Duration(minutes: task.alarmMinutesBefore!));
  }

  /// 개별 다음 일정 알림 등록
  static Future<void> scheduleTaskAlarm(TaskItem task) async {
    _activeTaskTimers[task.id]?.cancel();
    _activeTaskTimers.remove(task.id);

    final alarmTime = getTaskAlarmDateTime(task);
    if (alarmTime == null) return;

    final now = DateTime.now();
    if (alarmTime.isAfter(now)) {
      final diff = alarmTime.difference(now);
      if (!kIsWeb && diff.inHours < 24) {
        _activeTaskTimers[task.id] = Timer(diff, () async {
          await _fireTaskAlarm(task);
        });
      }

      // 모바일 네이티브 알림 예약 (백그라운드 및 기기 화면 꺼짐 시에도 도달)
      final taskIdInt = task.id.hashCode.abs() % 100000 + 1000;
      final timeLabel = task.time ?? '';
      final whenLabel = task.alarmMinutesBefore == 0
          ? '지금 예정된 일정입니다.'
          : '${task.alarmMinutesBefore}분 후 예정된 일정입니다 ($timeLabel).';
      final body = '📌 ${task.title}\n$whenLabel';
      await scheduleNativeTaskNotification(
        id: taskIdInt,
        title: '⏰ audistine 다음 일정 알림',
        body: body,
        scheduledDate: alarmTime,
      );
    }

    startMonitoring();
    await _syncTasksToLocalStorage();
    debugPrint(
      '[NotificationService] 일정 알람 등록: [${task.title}] 예정 시각: $alarmTime',
    );
  }

  /// 모든 일정 알람 재설정 (앱 구동 및 일정 갱신 시 호출)
  static Future<void> rescheduleAllTaskAlarms(List<TaskItem> tasks) async {
    for (final timer in _activeTaskTimers.values) {
      timer.cancel();
    }
    _activeTaskTimers.clear();

    final now = DateTime.now();
    for (final task in tasks) {
      if (task.isCompleted || task.alarmMinutesBefore == null) continue;
      final alarmTime = getTaskAlarmDateTime(task);
      if (alarmTime == null || !alarmTime.isAfter(now)) continue;

      final diff = alarmTime.difference(now);
      if (!kIsWeb && diff.inHours < 24) {
        _activeTaskTimers[task.id] = Timer(diff, () async {
          await _fireTaskAlarm(task);
        });
      }

      // 모바일 네이티브 알림 동기화 예약
      final taskIdInt = task.id.hashCode.abs() % 100000 + 1000;
      final timeLabel = task.time ?? '';
      final whenLabel = task.alarmMinutesBefore == 0
          ? '지금 예정된 일정입니다.'
          : '${task.alarmMinutesBefore}분 후 예정된 일정입니다 ($timeLabel).';
      final body = '📌 ${task.title}\n$whenLabel';
      await scheduleNativeTaskNotification(
        id: taskIdInt,
        title: '⏰ audistine 다음 일정 알림',
        body: body,
        scheduledDate: alarmTime,
      );
    }

    startMonitoring();
    await _syncTasksToLocalStorage(tasks);
    debugPrint(
      '[NotificationService] 전체 일정 알람 재설정 (${_activeTaskTimers.length}개 타이머 활성)',
    );
  }

  /// 일정 알람 취소
  static Future<void> cancelTaskAlarm(String taskId) async {
    _activeTaskTimers[taskId]?.cancel();
    _activeTaskTimers.remove(taskId);
    final taskIdInt = taskId.hashCode.abs() % 100000 + 1000;
    await cancelNativeNotification(taskIdInt);
    await _syncTasksToLocalStorage();
    debugPrint('[NotificationService] 일정 알람 취소: $taskId');
  }

  /// 다음 일정 실제 알림 발송 및 싱잉볼 명상음 재생
  static Future<void> _fireTaskAlarm(TaskItem task) async {
    try {
      final timeLabel = task.time ?? '';
      final whenLabel = task.alarmMinutesBefore == 0
          ? '지금 예정된 일정입니다.'
          : '${task.alarmMinutesBefore}분 후 예정된 일정입니다 ($timeLabel).';
      final body = '📌 ${task.title}\n$whenLabel';

      await showPlatformNotification(
        title: '⏰ audistine 다음 일정 알림',
        body: body,
        icon: 'icons/Icon-192.png',
      );

      try {
        await SoundService.playChime();
      } catch (_) {}

      final alarmTime = getTaskAlarmDateTime(task);
      if (alarmTime != null) {
        final key = '${task.id}_${alarmTime.millisecondsSinceEpoch}';
        final prefs = await SharedPreferences.getInstance();
        final notifiedKeys =
            (prefs.getStringList('audistine_notified_task_alarms') ?? [])
                .toSet();
        notifiedKeys.add(key);
        await prefs.setStringList(
          'audistine_notified_task_alarms',
          notifiedKeys.toList(),
        );
        syncNotifiedTaskKeyToLocalStorage(key);
      }
    } catch (e) {
      debugPrint('[NotificationService] 일정 알람 발송 에러: $e');
    }
  }

  /// 15초 주기 모니터링 시 미발송 일정 알람 체크 (Watchdog)
  static Future<void> _checkAndTriggerTaskAlarms() async {
    try {
      final tasks = await StorageService.loadTasks();
      final now = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      final notifiedKeys =
          (prefs.getStringList('audistine_notified_task_alarms') ?? []).toSet();

      for (final task in tasks) {
        if (task.isCompleted || task.alarmMinutesBefore == null) continue;
        final alarmTime = getTaskAlarmDateTime(task);
        if (alarmTime == null) continue;

        final key = '${task.id}_${alarmTime.millisecondsSinceEpoch}';
        if (notifiedKeys.contains(key)) continue;

        final diffSeconds = now.difference(alarmTime).inSeconds;
        if (now.isAfter(alarmTime) && diffSeconds <= 600) {
          debugPrint('[NotificationService] 일정 알람 트리거 (워치독): ${task.title}');
          await _fireTaskAlarm(task);
        }
      }
    } catch (e) {
      debugPrint('[NotificationService] _checkAndTriggerTaskAlarms 에러: $e');
    }
  }

  /// 웹 백그라운드 감시용 LocalStorage Task JSON 동기화
  static Future<void> _syncTasksToLocalStorage([List<TaskItem>? tasks]) async {
    try {
      final list = tasks ?? await StorageService.loadTasks();
      final exportList = <Map<String, dynamic>>[];
      for (final t in list) {
        if (t.isCompleted || t.alarmMinutesBefore == null) continue;
        final at = getTaskAlarmDateTime(t);
        if (at == null) continue;
        exportList.add({
          'id': t.id,
          'title': t.title,
          'time': t.time ?? '',
          'alarmMinutesBefore': t.alarmMinutesBefore,
          'alarmTimeMs': at.millisecondsSinceEpoch,
          'label': t.alarmLabel,
        });
      }
      syncTaskAlarmsToLocalStorage(jsonEncode(exportList));
    } catch (_) {}
  }

  static ({int hour, int minute})? parseTimeString(String? timeStr) {
    if (timeStr == null || timeStr.trim().isEmpty) return null;
    try {
      final raw = timeStr.trim();
      int hour = 9;
      int minute = 0;

      if (raw.contains('오전') || raw.contains('오후')) {
        final isPm = raw.contains('오후');
        final clean = raw.replaceAll('오전', '').replaceAll('오후', '').trim();
        final hm = clean.split(':');
        if (hm.length >= 2) {
          hour = int.parse(hm[0].trim());
          minute = int.parse(hm[1].trim());
          if (isPm && hour < 12) hour += 12;
          if (!isPm && hour == 12) hour = 0;
          return (hour: hour, minute: minute);
        }
      } else if (raw.toUpperCase().contains('AM') ||
          raw.toUpperCase().contains('PM')) {
        final isPm = raw.toUpperCase().contains('PM');
        final clean = raw.replaceAll(_alphabetRegex, '').trim();
        final hm = clean.split(':');
        if (hm.length >= 2) {
          hour = int.parse(hm[0].trim());
          minute = int.parse(hm[1].trim());
          if (isPm && hour < 12) hour += 12;
          if (!isPm && hour == 12) hour = 0;
          return (hour: hour, minute: minute);
        }
      } else if (raw.contains(':')) {
        final hm = raw.split(':');
        if (hm.length >= 2) {
          hour = int.parse(hm[0].trim());
          minute = int.parse(hm[1].trim());
          return (hour: hour, minute: minute);
        }
      }
    } catch (e) {
      debugPrint('시간 파싱 에러 ($timeStr): $e');
    }
    return null;
  }
}
