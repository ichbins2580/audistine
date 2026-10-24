import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';

final FlutterLocalNotificationsPlugin _notificationsPlugin =
    FlutterLocalNotificationsPlugin();
bool _isInitialized = false;

/// 모바일(Android / iOS) 네이티브 알림 초기화
Future<void> initPlatformNotifications() async {
  if (_isInitialized) return;
  try {
    // 1. Timezone 초기화
    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
    } catch (_) {
      // Fallback if specific timezone location is not found
    }

    // 2. 플랫폼별 초기화 설정
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _notificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        try {
          final uri = Uri.parse('https://audistine.web.app');
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        } catch (e) {
          debugPrint('[NativeNotification] URL 열기 에러: $e');
        }
      },
    );

    // 3. Android 8.0+ 알림 채널 생성
    const androidChannel = AndroidNotificationChannel(
      'audistine_channel',
      'audistine 알림',
      description: 'audistine 오늘의 명언 및 일정 알림',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(androidChannel);
    }

    _isInitialized = true;
    debugPrint('[NativeNotification] 모바일 네이티브 알림 초기화 완료');
  } catch (e) {
    debugPrint('[NativeNotification] 초기화 실패: $e');
  }
}

Future<bool> syncDailyPushConfig(
  int hour,
  int minute,
  bool enabled,
  int deviceSeed,
) async => true;

/// 알림 권한 요청 (Android 13+ 및 iOS)
Future<bool> requestPlatformNotificationPermission() async {
  await initPlatformNotifications();
  try {
    final androidImpl = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImpl != null) {
      final notifGranted = await androidImpl.requestNotificationsPermission();
      try {
        await androidImpl.requestExactAlarmsPermission();
      } catch (_) {}
      return notifGranted ?? false;
    }

    final iosImpl = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (iosImpl != null) {
      final granted = await iosImpl.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
  } catch (e) {
    debugPrint('[NativeNotification] 권한 요청 에러: $e');
  }
  return true;
}

/// 즉각적인 알림 노출
Future<bool> showPlatformNotification({
  required String title,
  required String body,
  String? icon,
}) async {
  await initPlatformNotifications();
  try {
    const androidDetails = AndroidNotificationDetails(
      'audistine_channel',
      'audistine 알림',
      channelDescription: 'audistine 오늘의 명언 및 일정 알림',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );
    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);
    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
    );
    return true;
  } catch (e) {
    debugPrint('[NativeNotification] showPlatformNotification 실패: $e');
    return false;
  }
}

/// 모바일 네이티브 매일 명언 반복 알림 예약
Future<void> scheduleNativeDailyNotification({
  required int id,
  required String title,
  required String body,
  required int hour,
  required int minute,
}) async {
  await initPlatformNotifications();
  try {
    const androidDetails = AndroidNotificationDetails(
      'audistine_channel',
      'audistine 알림',
      channelDescription: 'audistine 오늘의 명언 및 일정 알림',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );
    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    debugPrint(
      '[NativeNotification] 매일 알림 스케줄 완료 ($hour:$minute, 대상: $scheduledDate)',
    );
  } catch (e) {
    debugPrint('[NativeNotification] scheduleNativeDailyNotification 실패: $e');
  }
}

/// 모바일 네이티브 특정 일정 시각 알림 예약
Future<void> scheduleNativeTaskNotification({
  required int id,
  required String title,
  required String body,
  required DateTime scheduledDate,
}) async {
  await initPlatformNotifications();
  try {
    const androidDetails = AndroidNotificationDetails(
      'audistine_channel',
      'audistine 알림',
      channelDescription: 'audistine 오늘의 명언 및 일정 알림',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );
    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);
    final now = tz.TZDateTime.now(tz.local);
    if (!tzDate.isAfter(now)) return;

    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tzDate,
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
    debugPrint('[NativeNotification] 일정 알림 스케줄 완료: $title at $tzDate');
  } catch (e) {
    debugPrint('[NativeNotification] scheduleNativeTaskNotification 실패: $e');
  }
}

/// 모바일 네이티브 알림 취소
Future<void> cancelNativeNotification(int id) async {
  try {
    await _notificationsPlugin.cancel(id: id);
    debugPrint('[NativeNotification] 알림 취소: id $id');
  } catch (e) {
    debugPrint('[NativeNotification] 알림 취소 실패: $e');
  }
}

/// 모바일 환경에서는 LocalStorage 대신 SharedPreferences가 사용되므로 no-op
void syncNotificationConfigToLocalStorage({
  required String prefix,
  required int hour,
  required int minute,
  required bool enabled,
  String? previewText,
}) {}

void syncLastNotifiedDateToLocalStorage({
  required String prefix,
  required String dateStr,
}) {}

void syncTaskAlarmsToLocalStorage(String tasksJson) {}

void syncNotifiedTaskKeyToLocalStorage(String key) {}

void syncLastDailySlotToLocalStorage(String slotKey) {}
