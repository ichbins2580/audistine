import 'dart:convert';
import 'dart:html' as html;
import 'dart:js_interop';

import 'package:flutter/foundation.dart';

@JS('audistineSyncPush')
external JSPromise<JSBoolean> _audistineSyncPush(
  JSNumber hour,
  JSNumber minute,
  JSBoolean enabled,
  JSNumber deviceSeed,
);

Future<bool> requestPlatformNotificationPermission() async {
  try {
    if (!html.Notification.supported) return false;
    if (html.Notification.permission == 'granted') return true;
    if (html.Notification.permission != 'denied') {
      final res = await html.Notification.requestPermission();
      return res == 'granted';
    }
  } catch (e) {
    debugPrint('[Notification] Permission error: $e');
  }
  return false;
}

void _playWebChimeSound() {
  try {
    final audio = html.AudioElement('sounds/chime.wav')..volume = 1.0;
    audio.play().catchError((_) {
      try {
        final audioFallback = html.AudioElement(
          'assets/assets/sounds/chime.wav',
        )..volume = 1.0;
        audioFallback.play().catchError((_) {});
      } catch (_) {}
    });
  } catch (_) {}
}

Future<bool> showPlatformNotification({
  required String title,
  required String body,
  String? icon,
}) async {
  try {
    if (!html.Notification.supported) return false;
    final iconUrl = icon ?? 'icons/Icon-192.png';

    if (html.Notification.permission != 'granted') {
      final granted = await requestPlatformNotificationPermission();
      if (!granted) return false;
    }

    // 알림 사운드(차임 종소리) 즉각 재생
    _playWebChimeSound();

    // 1. Service Worker registration (never hang on .ready!)
    try {
      final reg = await html.window.navigator.serviceWorker?.getRegistration();
      if (reg != null) {
        await reg.showNotification(title, {
          'body': body,
          'icon': iconUrl,
          'badge': iconUrl,
          'vibrate': [200, 100, 200],
          'tag': 'audistine_${DateTime.now().millisecondsSinceEpoch}',
          'renotify': true,
          'silent': false,
          'data': {'url': 'https://audistine.web.app'},
        });
        return true;
      }
    } catch (swError) {
      debugPrint(
        '[Notification] ServiceWorker notification fallback: $swError',
      );
    }

    // 2. Desktop Window Notification
    try {
      final notif = html.Notification(
        title,
        body: body,
        icon: iconUrl,
        tag: 'audistine_${DateTime.now().millisecondsSinceEpoch}',
      );
      notif.onClick.listen((_) {
        try {
          html.window.open('https://audistine.web.app', '_blank');
        } catch (_) {}
      });
      return true;
    } catch (winError) {
      debugPrint('[Notification] Window Notification fallback: $winError');
    }
  } catch (e) {
    debugPrint('[Notification] showPlatformNotification error: $e');
  }
  return false;
}

void syncNotificationConfigToLocalStorage({
  required String prefix,
  required int hour,
  required int minute,
  required bool enabled,
  String? previewText,
}) {
  try {
    html.window.localStorage['${prefix}notify_hour'] = hour.toString();
    html.window.localStorage['${prefix}notify_minute'] = minute.toString();
    html.window.localStorage['${prefix}notify_enabled'] = enabled
        ? 'true'
        : 'false';
    if (previewText != null) {
      html.window.localStorage['${prefix}preview_text'] = previewText;
    }
  } catch (e) {
    debugPrint('[Notification] syncNotificationConfigToLocalStorage error: $e');
  }
}

void syncLastNotifiedDateToLocalStorage({
  required String prefix,
  required String dateStr,
}) {
  try {
    html.window.localStorage['${prefix}last_daily_notified_date'] = dateStr;
  } catch (e) {
    debugPrint('[Notification] syncLastNotifiedDateToLocalStorage error: $e');
  }
}

void syncTaskAlarmsToLocalStorage(String tasksJson) {
  try {
    html.window.localStorage['audistine_task_alarms'] = tasksJson;
  } catch (e) {
    debugPrint('[Notification] syncTaskAlarmsToLocalStorage error: $e');
  }
}

void syncNotifiedTaskKeyToLocalStorage(String key) {
  try {
    final raw =
        html.window.localStorage['audistine_notified_task_alarms'] ?? '[]';
    List<dynamic> list = [];
    try {
      list = (raw.isNotEmpty) ? (jsonDecode(raw) as List<dynamic>) : [];
    } catch (_) {}
    if (!list.contains(key)) {
      list.add(key);
      html.window.localStorage['audistine_notified_task_alarms'] = jsonEncode(
        list,
      );
    }
  } catch (e) {
    debugPrint('[Notification] syncNotifiedTaskKeyToLocalStorage error: $e');
  }
}

void syncLastDailySlotToLocalStorage(String slotKey) {
  try {
    html.window.localStorage['audistine_last_daily_slot'] = slotKey;
  } catch (e) {
    debugPrint('[Notification] syncLastDailySlotToLocalStorage error: $e');
  }
}

Future<void> initPlatformNotifications() async {}

Future<bool> syncDailyPushConfig(
  int hour,
  int minute,
  bool enabled,
  int deviceSeed,
) async {
  try {
    final result = await _audistineSyncPush(
      hour.toJS,
      minute.toJS,
      enabled.toJS,
      deviceSeed.toJS,
    ).toDart;
    return result.toDart;
  } catch (e) {
    debugPrint('[Notification] 서버 푸시 설정 동기화 실패: $e');
    return false;
  }
}

Future<void> scheduleNativeDailyNotification({
  required int id,
  required String title,
  required String body,
  required int hour,
  required int minute,
}) async {}

Future<void> scheduleNativeTaskNotification({
  required int id,
  required String title,
  required String body,
  required DateTime scheduledDate,
}) async {}

Future<void> cancelNativeNotification(int id) async {}
