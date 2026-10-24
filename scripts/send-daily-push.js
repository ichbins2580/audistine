#!/usr/bin/env node
'use strict';

const fs = require('node:fs');
const path = require('node:path');
const { cert, initializeApp } = require('firebase-admin/app');
const { getDatabase } = require('firebase-admin/database');
const { getMessaging } = require('firebase-admin/messaging');

const PROJECT_ID = 'audistine-hub';
const DATABASE_URL = 'https://audistine-hub-default-rtdb.firebaseio.com';
const SITE_URL = 'https://audistine.web.app/';
const ICON_URL = `${SITE_URL}icons/Icon-192.png`;
const DRY_RUN = process.env.DRY_RUN === 'true';
const SEND_TEST = process.env.SEND_TEST === 'true';
const TEST_DEVICE_ID = process.env.TEST_DEVICE_ID || '';
const LATE_WINDOW_MINUTES = 24 * 60;
const MAX_PARALLEL_SENDS = 20;

function loadServiceAccount() {
  const credentialFile = process.env.FIREBASE_SERVICE_ACCOUNT_FILE ||
    process.env.GOOGLE_APPLICATION_CREDENTIALS;
  if (!credentialFile) {
    throw new Error('Firebase service-account credential file is not configured.');
  }

  const serialized = fs.readFileSync(credentialFile, 'utf8');
  // Accept a UTF-8 BOM from files saved by some editors without logging the secret.
  const normalized = serialized.replace(/^\uFEFF/, '').trim();
  let account;
  try {
    account = JSON.parse(normalized);
  } catch (_) {
    throw new Error('Firebase service-account credential is not valid JSON. Verify the GitHub secret contains the complete JSON file.');
  }
  if (account.project_id !== PROJECT_ID || !account.client_email || !account.private_key) {
    throw new Error(`The service account must belong to Firebase project ${PROJECT_ID}.`);
  }
  return account;
}

function getLocalClock(date, timeZone) {
  try {
    const parts = new Intl.DateTimeFormat('en-CA', {
      timeZone,
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
      hourCycle: 'h23',
    }).formatToParts(date);
    const fields = Object.fromEntries(parts.map(({ type, value }) => [type, value]));
    const hour = Number(fields.hour) % 24;
    return {
      date: `${fields.year}-${fields.month}-${fields.day}`,
      minuteOfDay: hour * 60 + Number(fields.minute),
    };
  } catch (_) {
    return null;
  }
}

function formatQuote(quotes, date, deviceSeed) {
  const dayKey = Number(date.replaceAll('-', ''));
  const quote = quotes[(dayKey + deviceSeed) % quotes.length];
  let body = quote.translation || quote.original || quote.english || '';
  if (quote.source) body += ` — ${quote.source}`;
  return body.slice(0, 1500);
}

function collectDueDevices(snapshot, now, { sendTest, testDeviceId }) {
  const devices = [];
  snapshot.forEach((userSnapshot) => {
    userSnapshot.forEach((deviceSnapshot) => {
      if (sendTest && deviceSnapshot.key !== testDeviceId) return;
      const device = deviceSnapshot.val();
      if (!device || device.enabled !== true || typeof device.token !== 'string' || !device.token) {
        return;
      }
      if (!Number.isInteger(device.hour) || device.hour < 0 || device.hour > 23 ||
          !Number.isInteger(device.minute) || device.minute < 0 || device.minute > 59 ||
          !Number.isInteger(device.deviceSeed) || device.deviceSeed < 0 || device.deviceSeed > 9999 ||
          typeof device.timeZone !== 'string') {
        console.warn('Skipping a push record with invalid schedule settings.');
        return;
      }

      const local = getLocalClock(now, device.timeZone);
      if (!local) {
        console.warn('Skipping a push record with an invalid time zone.');
        return;
      }
      const targetMinute = device.hour * 60 + device.minute;
      const minutesLate = local.minuteOfDay - targetMinute;
      if (!sendTest && (minutesLate < 0 || minutesLate > LATE_WINDOW_MINUTES ||
          device.lastSentDate === local.date)) {
        return;
      }

      devices.push({ ref: deviceSnapshot.ref, device, localDate: local.date });
    });
  });
  return devices;
}

async function claimDailySlot(ref, date) {
  const result = await ref.child('lastSentDate').transaction((previous) => {
    if (previous === date) return;
    return date;
  });
  return result.committed;
}

async function releaseDailySlot(ref, date) {
  await ref.child('lastSentDate').transaction((previous) => (
    previous === date ? null : previous
  ));
}

async function sendOne(messaging, entry, quotes, { sendTest }) {
  const { ref, device, localDate } = entry;
  if (!sendTest && !(await claimDailySlot(ref, localDate))) return 'already-sent';

  if (DRY_RUN) {
    if (!sendTest) await releaseDailySlot(ref, localDate);
    console.log(`DRY_RUN: ${sendTest ? 'test' : 'scheduled'} push eligible for ${device.hour.toString().padStart(2, '0')}:${device.minute.toString().padStart(2, '0')} ${device.timeZone} on ${localDate}.`);
    return 'dry-run';
  }

  try {
    const quote = formatQuote(quotes, localDate, device.deviceSeed);
    const body = sendTest ? `테스트 알림입니다.\n${quote}` : quote;
    await messaging.send({
      token: device.token,
      data: {
        type: sendTest ? 'test' : 'daily_quote',
        date: localDate,
        title: sendTest ? 'audistine 푸시 테스트' : '오늘의 명언이 도착했습니다.',
        body,
        icon: ICON_URL,
        tag: sendTest
          ? `audistine_test_${Date.now()}`
          : `audistine_${localDate}_${device.hour}_${device.minute}`,
        url: SITE_URL,
      },
      webpush: {
        headers: { Urgency: 'high', TTL: '3600' },
        fcmOptions: { link: SITE_URL },
      },
    });
    return 'sent';
  } catch (error) {
    if (error.code === 'messaging/registration-token-not-registered' ||
        error.code === 'messaging/invalid-registration-token') {
      await ref.remove();
      console.log('Removed an expired push registration.');
      return 'removed';
    }
    if (!sendTest) await releaseDailySlot(ref, localDate);
    console.error(`FCM delivery failed (${error.code || 'unknown'}).`);
    return 'failed';
  }
}

async function forEachLimit(items, limit, callback) {
  let next = 0;
  const workers = Array.from({ length: Math.min(limit, items.length) }, async () => {
    while (next < items.length) {
      const index = next++;
      await callback(items[index]);
    }
  });
  await Promise.all(workers);
}

async function main() {
  if (SEND_TEST && !TEST_DEVICE_ID) {
    throw new Error('A device ID is required for a one-device test send.');
  }
  const serviceAccount = loadServiceAccount();
  const app = initializeApp({
    credential: cert(serviceAccount),
    databaseURL: DATABASE_URL,
    projectId: PROJECT_ID,
  });
  const db = getDatabase(app);
  const messaging = getMessaging(app);
  const quotePath = path.resolve(__dirname, '..', 'assets', 'tale.json');
  const quotes = JSON.parse(fs.readFileSync(quotePath, 'utf8'));
  if (!Array.isArray(quotes) || quotes.length === 0) {
    throw new Error('assets/tale.json has no quotes.');
  }

  const snapshot = await db.ref('pushSubscriptions').get();
  if (!snapshot.exists()) {
    console.log('No registered push devices.');
    return;
  }

  const devices = collectDueDevices(snapshot, new Date(), {
    sendTest: SEND_TEST,
    testDeviceId: TEST_DEVICE_ID,
  });
  if (SEND_TEST && devices.length !== 1) {
    throw new Error('The specified device ID was not found or is not subscribed/enabled.');
  }

  const counts = { sent: 0, removed: 0, failed: 0, 'already-sent': 0, 'dry-run': 0 };
  await forEachLimit(devices, MAX_PARALLEL_SENDS, async (entry) => {
    const result = await sendOne(messaging, entry, quotes, { sendTest: SEND_TEST });
    counts[result] += 1;
  });

  console.log(`Push run complete: ${JSON.stringify(counts)}${DRY_RUN ? ' (dry run)' : ''}`);
  if (counts.failed > 0) process.exitCode = 1;
}

main().catch((error) => {
  console.error(`Daily push job failed: ${error.message}`);
  process.exitCode = 1;
});
