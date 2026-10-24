import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/diary_entry.dart';
import '../models/task_item.dart';
import '../models/belief_model.dart';
import '../models/imagery_model.dart';
import '../models/mind_test_model.dart';
import '../models/self_connection_test_model.dart';
import '../models/belief_test_model.dart';
import '../models/survival_rule_test_model.dart';

class StorageService {
  static const String _diaryKey = 'audistine_diaries';
  static const String _tasksKey = 'audistine_tasks';
  static const String _beliefsKey = 'audistine_user_beliefs';
  static const String _imageryKey = 'audistine_imagery_slots';
  static const String _mindTestKey = 'audistine_mind_test_results';
  static const String _selfConnectionTestKey = 'audistine_self_connection_test_results';
  static const String _beliefTestKey = 'audistine_belief_test_results';
  static const String _survivalRuleTestKey = 'audistine_survival_rule_test_results';

  // --- 평온의 심상화 사진 슬롯 저장/불러오기 (3개 독립 키 방식) ---
  static Future<List<ImagerySlot>> loadImagerySlots() async {
    final prefs = await SharedPreferences.getInstance();
    final List<ImagerySlot> slots = [];
    final defaults = ImagerySlot.defaultSlots();

    for (int i = 0; i < 3; i++) {
      final singleJson = prefs.getString('${_imageryKey}_$i');
      if (singleJson != null && singleJson.isNotEmpty) {
        try {
          final decoded = json.decode(singleJson);
          slots.add(ImagerySlot.fromJson(decoded as Map<String, dynamic>));
          continue;
        } catch (_) {}
      }
      slots.add(defaults[i]);
    }
    return slots;
  }

  static Future<void> saveImagerySlot(int index, ImagerySlot slot) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = json.encode(slot.toJson());
      await prefs.setString('${_imageryKey}_$index', encoded);
    } catch (e) {
      debugPrint('슬롯 $index 저장 오류: $e');
    }
  }

  // --- 감정 일기 저장/불러오기 ---
  static Future<List<DiaryEntry>> loadDiaries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_diaryKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final List<dynamic> list = json.decode(raw);
      return list.map((e) => DiaryEntry.fromJson(e as Map<String, dynamic>)).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      debugPrint('일기 로딩 오류: $e');
      return [];
    }
  }

  static Future<void> saveDiary(DiaryEntry entry) async {
    final list = await loadDiaries();
    final idx = list.indexWhere((e) => e.id == entry.id);
    if (idx >= 0) {
      list[idx] = entry;
    } else {
      list.insert(0, entry);
    }

    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(list.map((e) => e.toJson()).toList());
    await prefs.setString(_diaryKey, encoded);
  }

  static Future<void> deleteDiary(String id) async {
    final list = await loadDiaries();
    list.removeWhere((e) => e.id == id);
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(list.map((e) => e.toJson()).toList());
    await prefs.setString(_diaryKey, encoded);
  }

  // --- 마음 신념 & 대처 보관함 ---
  static Future<List<UserBeliefEntry>> loadUserBeliefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_beliefsKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final List<dynamic> list = json.decode(raw);
      return list.map((e) => UserBeliefEntry.fromJson(e as Map<String, dynamic>)).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      debugPrint('신념 로딩 오류: $e');
      return [];
    }
  }

  static Future<void> saveUserBelief(UserBeliefEntry entry) async {
    final list = await loadUserBeliefs();
    final idx = list.indexWhere((e) => e.id == entry.id);
    if (idx >= 0) {
      list[idx] = entry;
    } else {
      list.insert(0, entry);
    }

    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(list.map((e) => e.toJson()).toList());
    await prefs.setString(_beliefsKey, encoded);
  }

  static Future<void> toggleBeliefExperiment(String id) async {
    final list = await loadUserBeliefs();
    final idx = list.indexWhere((e) => e.id == id);
    if (idx >= 0) {
      list[idx] = list[idx].copyWith(isCompletedExperiment: !list[idx].isCompletedExperiment);
      final prefs = await SharedPreferences.getInstance();
      final encoded = json.encode(list.map((e) => e.toJson()).toList());
      await prefs.setString(_beliefsKey, encoded);
    }
  }

  static Future<void> deleteUserBelief(String id) async {
    final list = await loadUserBeliefs();
    list.removeWhere((e) => e.id == id);
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(list.map((e) => e.toJson()).toList());
    await prefs.setString(_beliefsKey, encoded);
  }

  // --- 다음 일정 저장/불러오기 ---
  static Future<List<TaskItem>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_tasksKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final List<dynamic> list = json.decode(raw);
      return list.map((e) => TaskItem.fromJson(e as Map<String, dynamic>)).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      debugPrint('일정 로딩 오류: $e');
      return [];
    }
  }

  static Future<void> saveTasks(List<TaskItem> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(tasks.map((e) => e.toJson()).toList());
    await prefs.setString(_tasksKey, encoded);
  }

  static Future<TaskItem> addTask(
    String title,
    String forDate, {
    String? time,
    int? alarmMinutesBefore = 5,
  }) async {
    final list = await loadTasks();
    final newItem = TaskItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      time: time,
      alarmMinutesBefore: alarmMinutesBefore,
      isCompleted: false,
      createdAt: DateTime.now(),
      forDate: forDate,
    );
    list.insert(0, newItem);
    await saveTasks(list);
    return newItem;
  }

  static Future<void> toggleTask(String id) async {
    final list = await loadTasks();
    final idx = list.indexWhere((e) => e.id == id);
    if (idx >= 0) {
      list[idx] = list[idx].copyWith(isCompleted: !list[idx].isCompleted);
      await saveTasks(list);
    }
  }

  static Future<TaskItem?> updateTaskAlarm(String id, int? alarmMinutesBefore) async {
    final list = await loadTasks();
    final idx = list.indexWhere((e) => e.id == id);
    if (idx >= 0) {
      list[idx] = list[idx].copyWith(
        alarmMinutesBefore: alarmMinutesBefore,
        clearAlarm: alarmMinutesBefore == null,
      );
      await saveTasks(list);
      return list[idx];
    }
    return null;
  }

  static Future<void> deleteTask(String id) async {
    final list = await loadTasks();
    list.removeWhere((e) => e.id == id);
    await saveTasks(list);
  }


  // --- 알림 시각 설정 ---
  static const String _dailyNotificationEnabledKey = 'audistine_daily_notification_enabled';

  static Future<bool> isDailyNotificationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_dailyNotificationEnabledKey) ?? true;
  }

  static Future<void> setDailyNotificationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dailyNotificationEnabledKey, enabled);
  }

  static Future<TimeOfDay> loadNotificationTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt('notifyHour') ?? 9;
    final minute = prefs.getInt('notifyMinute') ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  static Future<void> saveNotificationTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notifyHour', time.hour);
    await prefs.setInt('notifyMinute', time.minute);
  }

  // --- 임상의 전용 알림 설정 ---
  static Future<bool> isClinicianDailyNotificationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('clinician_daily_notification_enabled') ?? true;
  }

  static Future<void> setClinicianDailyNotificationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('clinician_daily_notification_enabled', enabled);
  }

  static Future<bool> isClinicianLetterNotificationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('clinician_letter_notification_enabled') ?? true;
  }

  static Future<void> setClinicianLetterNotificationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('clinician_letter_notification_enabled', enabled);
  }

  static Future<TimeOfDay> loadClinicianNotificationTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt('clinicianNotifyHour') ?? prefs.getInt('clinician_notify_hour') ?? 9;
    final minute = prefs.getInt('clinicianNotifyMinute') ?? prefs.getInt('clinician_notify_minute') ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  static Future<void> saveClinicianNotificationTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('clinicianNotifyHour', time.hour);
    await prefs.setInt('clinicianNotifyMinute', time.minute);
    await prefs.setInt('clinician_notify_hour', time.hour);
    await prefs.setInt('clinician_notify_minute', time.minute);
  }

  // --- 일일 알림 최근 발송 날짜 추적 (중복 발송 방지) ---
  static const String _lastDailyNotifiedDateKey = 'audistine_last_daily_notified_date';
  static const String _lastClinicianDailyNotifiedDateKey = 'clinician_last_daily_notified_date';

  static Future<String?> getLastDailyNotifiedDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastDailyNotifiedDateKey);
  }

  static Future<void> setLastDailyNotifiedDate(String dateStr) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastDailyNotifiedDateKey, dateStr);
  }

  static Future<String?> getLastClinicianDailyNotifiedDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastClinicianDailyNotifiedDateKey);
  }

  static Future<void> setLastClinicianDailyNotifiedDate(String dateStr) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastClinicianDailyNotifiedDateKey, dateStr);
  }


  // --- 마음 검사 결과 저장/불러오기 ---
  static Future<List<MindTestResult>> loadMindTestResults() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_mindTestKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final List<dynamic> list = json.decode(raw);
      return list.map((e) => MindTestResult.fromJson(e as Map<String, dynamic>)).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      debugPrint('마음 검사 결과 로딩 오류: $e');
      return [];
    }
  }

  static Future<void> saveMindTestResult(MindTestResult result) async {
    final list = await loadMindTestResults();
    final idx = list.indexWhere((e) => e.id == result.id);
    if (idx >= 0) {
      list[idx] = result;
    } else {
      list.insert(0, result);
    }

    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(list.map((e) => e.toJson()).toList());
    await prefs.setString(_mindTestKey, encoded);
  }

  static Future<void> deleteMindTestResult(String id) async {
    final list = await loadMindTestResults();
    list.removeWhere((e) => e.id == id);
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(list.map((e) => e.toJson()).toList());
    await prefs.setString(_mindTestKey, encoded);
  }

  // --- 자존감 & 외로움 절대 평가 검사 결과 저장/불러오기 ---
  static Future<List<SelfConnectionTestResult>> loadSelfConnectionTestResults() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_selfConnectionTestKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final List<dynamic> list = json.decode(raw);
      return list
          .map((e) => SelfConnectionTestResult.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      debugPrint('자존감&연결감 검사 결과 로딩 오류: $e');
      return [];
    }
  }

  static Future<void> saveSelfConnectionTestResult(SelfConnectionTestResult result) async {
    final list = await loadSelfConnectionTestResults();
    final idx = list.indexWhere((e) => e.id == result.id);
    if (idx >= 0) {
      list[idx] = result;
    } else {
      list.insert(0, result);
    }

    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(list.map((e) => e.toJson()).toList());
    await prefs.setString(_selfConnectionTestKey, encoded);
  }

  static Future<void> deleteSelfConnectionTestResult(String id) async {
    final list = await loadSelfConnectionTestResults();
    list.removeWhere((e) => e.id == id);
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(list.map((e) => e.toJson()).toList());
    await prefs.setString(_selfConnectionTestKey, encoded);
  }

  // --- 핵심신념 검사 결과 저장/불러오기 ---
  static Future<List<BeliefTestResult>> loadBeliefTestResults() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_beliefTestKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final List<dynamic> list = json.decode(raw);
      return list
          .map((e) => BeliefTestResult.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      debugPrint('핵심신념 검사 결과 로딩 오류: $e');
      return [];
    }
  }

  static Future<void> saveBeliefTestResult(BeliefTestResult result) async {
    final list = await loadBeliefTestResults();
    final idx = list.indexWhere((e) => e.id == result.id);
    if (idx >= 0) {
      list[idx] = result;
    } else {
      list.insert(0, result);
    }

    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(list.map((e) => e.toJson()).toList());
    await prefs.setString(_beliefTestKey, encoded);
  }

  static Future<void> deleteBeliefTestResult(String id) async {
    final list = await loadBeliefTestResults();
    list.removeWhere((e) => e.id == id);
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(list.map((e) => e.toJson()).toList());
    await prefs.setString(_beliefTestKey, encoded);
  }

  // --- 삶의 규칙 검사 결과 저장/불러오기 ---
  static Future<List<SurvivalRuleTestResult>> loadSurvivalRuleTestResults() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_survivalRuleTestKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final List<dynamic> list = json.decode(raw);
      return list
          .map((e) => SurvivalRuleTestResult.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      debugPrint('삶의 규칙 검사 결과 로딩 오류: $e');
      return [];
    }
  }

  static Future<void> saveSurvivalRuleTestResult(SurvivalRuleTestResult result) async {
    final list = await loadSurvivalRuleTestResults();
    final idx = list.indexWhere((e) => e.id == result.id);
    if (idx >= 0) {
      list[idx] = result;
    } else {
      list.insert(0, result);
    }

    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(list.map((e) => e.toJson()).toList());
    await prefs.setString(_survivalRuleTestKey, encoded);
  }

  static Future<void> deleteSurvivalRuleTestResult(String id) async {
    final list = await loadSurvivalRuleTestResults();
    list.removeWhere((e) => e.id == id);
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(list.map((e) => e.toJson()).toList());
    await prefs.setString(_survivalRuleTestKey, encoded);
  }
}
