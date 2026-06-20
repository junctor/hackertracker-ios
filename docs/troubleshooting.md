# Troubleshooting

Common problems and how to fix them.

## Schedule looks empty

The conference data is fetched from Firebase Firestore on launch and then continuously listened to. If the schedule is blank:

1. Check your **internet connection**.
2. Pull-to-refresh the schedule (drag down at the top of the list).
3. **Settings → Select Conference** — make sure the right conference is active.
4. Force-quit the app (swipe up from the home indicator, swipe up on the HackerTracker card) and relaunch.
5. If the schedule is still empty for an active conference, the conference data may not have been published yet by the organizers. Check the conference's official channels.

## Maps not loading

Maps are downloaded once per conference and cached at `<documents>/<conference_code>/<filename>`.

1. **Tab icon pulses?** Wait — maps are still downloading in the background.
2. **Beezle bobbing with "Map downloading…"?** Same — the empty state during download.
3. **Pull to refresh on the Maps tab** — pulls the conference data again, which re-triggers map downloads.
4. **Force-quit and relaunch** — sometimes a hung URLSession is the culprit.
5. If maps stay broken, **Settings → Select Conference → re-select your conference** — this forces a fresh fetch.

## Notes (or bookmarks, or custom events) not syncing across devices

These use **iCloud private database** via Core Data + NSPersistentCloudKitContainer.

1. **Are both devices signed into the same Apple ID?** This is the most common cause.
2. **Is iCloud Drive enabled** on both devices? **Settings → [your name] → iCloud → iCloud Drive** must be on.
3. **Are you in low-power mode?** iOS deprioritizes CloudKit sync in low-power mode.
4. **Wait 30-60 seconds.** CloudKit isn't real-time; it batches changes for efficiency.
5. **Toggle iCloud sync off and on for HackerTracker:** Settings → iCloud → HackerTracker → off → on.

If it still doesn't sync, file an issue.

## App crashed

Crash reports are sent to **Firebase Crashlytics** automatically on next launch. You don't need to do anything.

If you can reliably reproduce the crash, please [open an issue](https://github.com/junctor/hackertracker-ios/issues) with steps to reproduce — that's far more useful than a bare crash report.

## Notifications not arriving

Per-event notifications (custom events) and conference-wide pushes are different paths:

**Custom event notifications** — uses the global "Before Event" minutes from Settings (default 20). Check:
1. Did you toggle "Send a notification before this event" on when creating the event? (Off by default.)
2. **iOS Settings → Notifications → HackerTracker** — Allow Notifications must be on.
3. The notification fires at `event_start - notifyAt_minutes`. If you set notifyAt to 20 and the event starts at 3:00 PM, the alert fires at 2:40 PM.

**Conference-wide push** — uses APNs/FCM:
1. Same: Allow Notifications must be on.
2. Sometimes APNs takes a moment to register a new install; relaunch a few times.

## AI summaries don't appear

If you don't see the sparkle ✨ on talk rows after toggling AI Summaries on:

1. **Check the toggle is actually on** — Settings → AI Summaries.
2. **iOS 26 or later required.** Older iOS versions hide the toggle entirely; if you don't see the toggle at all, your device or OS doesn't support it.
3. **Apple Intelligence enabled?** iOS Settings → Apple Intelligence & Siri.
4. **Wait a few seconds.** The first time you scroll to a row, the model needs ~1-3 seconds to generate the summary. Subsequent visits are instant (cached).
5. **The talk description is under 100 characters?** Then there's nothing to summarize — short blurbs are skipped intentionally.

## Custom event QR scan doesn't open the form

If scanning a QR code with iOS Camera opens HackerTracker but doesn't show the import form:

1. **Is the URL well-formed?** It should start with `hackertracker://import/customEvent?t=...&b=...&e=...`.
2. **The encoding might be off.** Try the **Share Link…** option in the share sheet on the sending side; AirDrop the link instead of scanning.
3. The recipient device's conferences must be loaded enough to render the form. Open the app, let it settle, then re-scan.

## How to file a bug

[GitHub Issues](https://github.com/junctor/hackertracker-ios/issues/new). Include:

- App version (Settings → About).
- iOS version.
- Device model.
- Steps to reproduce.
- Expected vs actual behavior.
- Screenshot if relevant.

For privacy concerns specifically, email **hackertracker@defcon.org**.

## See also

- [Privacy and tracking](privacy.md)
- [Quick Start](quickstart.md)
