// audistine Service Worker for Notifications
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyCrLIAc-dE2sSvb3DFwOgVVZ97SMDbmihM',
  authDomain: 'audistine-hub.firebaseapp.com',
  databaseURL: 'https://audistine-hub-default-rtdb.firebaseio.com',
  projectId: 'audistine-hub',
  storageBucket: 'audistine-hub.firebasestorage.app',
  messagingSenderId: '18797952280',
  appId: '1:18797952280:web:1115ddf041b4d73a63b26d',
});

var messaging = firebase.messaging();
messaging.onBackgroundMessage(function(payload) {
  var data = payload.data || {};
  return self.registration.showNotification(data.title || '오늘의 명언이 도착했습니다.', {
    body: data.body || 'audistine을 열어 오늘의 명언을 확인해 보세요.',
    icon: data.icon || 'icons/Icon-192.png',
    badge: data.icon || 'icons/Icon-192.png',
    tag: data.tag || 'audistine_daily_quote',
    renotify: false,
    data: { url: data.url || 'https://audistine.web.app/' },
  });
});

self.addEventListener('install', function(event) {
  self.skipWaiting();
});

self.addEventListener('activate', function(event) {
  event.waitUntil(self.clients.claim());
});

// 알림 클릭 시 https://audistine.web.app 으로 이동
self.addEventListener('notificationclick', function(event) {
  event.notification.close();

  var targetUrl = (event.notification.data && event.notification.data.url)
    ? event.notification.data.url
    : 'https://audistine.web.app';

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function(clientList) {
      for (var i = 0; i < clientList.length; i++) {
        var client = clientList[i];
        if (client.url && (client.url.indexOf('audistine.web.app') !== -1 || client.url.indexOf(self.location.origin) !== -1) && 'focus' in client) {
          if ('navigate' in client && targetUrl && client.url.indexOf('audistine.web.app') === -1) {
            client.navigate(targetUrl);
          }
          return client.focus();
        }
      }
      if (clients.openWindow) {
        return clients.openWindow(targetUrl);
      }
    })
  );
});
