# audistine daily push via GitHub Actions

The sender reads `pushSubscriptions/{anonymousUid}/{deviceId}` using Firebase Admin and sends FCM Web Push. The web app stores each browser token and its local notification schedule at that path. Realtime Database rules allow access only to the owning anonymous Firebase user; the GitHub service account can read the database.

## GitHub repository setup

1. Ensure the repository's **Actions** feature and workflow permissions are enabled.
2. Add an Actions repository secret named exactly `FIREBASE_SERVICE_ACCOUNT`. Its value must be the **single-line Base64 encoding of the complete JSON** for a Firebase service account in project `audistine-hub` (not raw JSON). The workflow decodes it into a permission-restricted temporary file, validates the JSON, and removes the file after the job. Grant that account only the permissions needed to read/update Realtime Database push registrations and send FCM messages (for example, appropriate Firebase Realtime Database and Firebase Cloud Messaging roles). Do not commit, print, or upload the credential file. If an account key has been exposed, revoke it and create a replacement before using this workflow.
3. Commit and push `.github/workflows/daily-push.yml`, `scripts/send-daily-push.js`, and `scripts/package.json` to the repository's default branch.
4. From the GitHub **Actions** tab, run **audistine daily quote push** manually with `dry_run` left checked to verify the workflow without sending.

## Daily schedule

The workflow checks registrations every five minutes so users can each choose a different notification time. For each enabled device, the script checks its saved IANA time zone and hour/minute, then sends that device's matching daily quote once for its local date. For example, a device set to 08:00 in Korea is checked around 23:00 UTC the previous day. GitHub scheduled workflows are best-effort and may be delayed. A successful send records `lastSentDate`; failed sends release the claim for retry on a later run. Expired tokens are deleted.

The first registered browser for each phone must visit `https://audistine.web.app`, allow notifications, and set a time under **명언 알림**. Android Chrome is supported. iPhone/iPad Web Push requires a supported OS version and the site added to the Home Screen.

## Immediate single-device test

For a real test at any time, manually run the workflow with:

- `dry_run`: unchecked
- `send_test`: checked
- `test_device_id`: the exact device-ID key under `pushSubscriptions/{anonymousUid}/{deviceId}`

The test mode is restricted to this single device ID and does not change its `lastSentDate`. Leaving `dry_run` checked sends nothing. A blank or unknown device ID fails instead of broadcasting to all subscribers. Do not paste service-account JSON or FCM tokens into workflow inputs or logs.

The sender loads credentials only from the decoded temporary JSON file and validates the Firebase project before accessing the database. The encoded secret is supplied only to the decode step, not checkout or dependency installation.
