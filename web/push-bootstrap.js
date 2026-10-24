(function () {
  'use strict';

  var config = window.audistinePushConfig;
  var instanceStorageKey = 'audistine_push_instance_id';
  var app;

  function instanceId() {
    var value = localStorage.getItem(instanceStorageKey);
    if (!value) {
      value = typeof crypto.randomUUID === 'function'
        ? crypto.randomUUID()
        : Array.from(crypto.getRandomValues(new Uint8Array(16)))
          .map(function (byte) { return byte.toString(16).padStart(2, '0'); })
          .join('');
      localStorage.setItem(instanceStorageKey, value);
    }
    return value;
  }

  function notificationSettings() {
    return {
      enabled: localStorage.getItem('audistine_notify_enabled') === 'true' ||
        localStorage.getItem('flutter.audistine_daily_notification_enabled') === 'true',
      hour: Number.parseInt(localStorage.getItem('audistine_notify_hour') || '9', 10),
      minute: Number.parseInt(localStorage.getItem('audistine_notify_minute') || '0', 10),
      timeZone: Intl.DateTimeFormat().resolvedOptions().timeZone || 'Asia/Seoul',
    };
  }

  async function firebaseReady() {
    if (!config || !config.vapidKey || !window.firebase) return null;
    try {
      app = window.firebase.apps.length
        ? window.firebase.app()
        : window.firebase.initializeApp(config.firebase);
      var messagingApi = window.firebase.messaging;
      if (!(await messagingApi.isSupported())) return null;
      return {
        auth: app.auth(),
        database: app.database(),
        messaging: app.messaging(),
      };
    } catch (error) {
      console.warn('[audistine push] Firebase messaging unavailable:', error);
      return null;
    }
  }

  async function signedInUser(auth) {
    if (auth.currentUser) return auth.currentUser;
    var result = await auth.signInAnonymously();
    return result.user;
  }

  window.audistineSyncPush = async function (hour, minute, enabled, deviceSeed) {
    if (!('Notification' in window) || Notification.permission !== 'granted') return false;
    var services = await firebaseReady();
    if (!services) return false;

    try {
      var user = await signedInUser(services.auth);
      var registration = await navigator.serviceWorker.register('/sw.js', {
        scope: '/push-notifications/',
      });
      var token = await services.messaging.getToken({
        vapidKey: config.vapidKey,
        serviceWorkerRegistration: registration,
      });
      if (!token) return false;

      var settings = notificationSettings();
      if (Number.isInteger(hour)) settings.hour = hour;
      if (Number.isInteger(minute)) settings.minute = minute;
      if (typeof enabled === 'boolean') settings.enabled = enabled;
      if (!Number.isInteger(deviceSeed) || deviceSeed < 0 || deviceSeed > 9999) return false;
      var deviceRef = services.database.ref(
        'pushSubscriptions/' + user.uid + '/' + instanceId(),
      );
      var previous = (await deviceRef.once('value')).val() || {};
      var record = Object.assign(settings, {
        token: token,
        deviceSeed: deviceSeed,
        updatedAt: Date.now(),
      });
      if (previous.hour === settings.hour &&
          previous.minute === settings.minute &&
          previous.enabled === settings.enabled &&
          previous.deviceSeed === deviceSeed &&
          previous.lastSentDate) {
        record.lastSentDate = previous.lastSentDate;
      }
      await deviceRef.set(record);
      return true;
    } catch (error) {
      console.warn('[audistine push] Registration failed:', error);
      return false;
    }
  };

  window.audistineRemovePush = async function () {
    var services = await firebaseReady();
    if (!services || !services.auth.currentUser) return false;
    try {
      var user = services.auth.currentUser;
      await services.database.ref(
        'pushSubscriptions/' + user.uid + '/' + instanceId(),
      ).remove();
      return true;
    } catch (error) {
      console.warn('[audistine push] Unsubscribe failed:', error);
      return false;
    }
  };

  window.addEventListener('load', function () {
    var settings = notificationSettings();
    if (settings.enabled && 'Notification' in window && Notification.permission === 'granted') {
      var deviceSeed = Number.parseInt(
        localStorage.getItem('flutter.audistine_device_seed') || '',
        10,
      );
      if (Number.isInteger(deviceSeed) && deviceSeed >= 0 && deviceSeed <= 9999) {
        window.audistineSyncPush(settings.hour, settings.minute, true, deviceSeed);
      }
    }
  });
})();
