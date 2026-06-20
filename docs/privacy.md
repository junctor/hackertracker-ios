# Privacy and tracking

Plain English version of what HackerTracker collects, doesn't collect, and how it handles your data. The in-app copy of this lives at **Settings → Privacy & Tracking** and stays in sync with this page.

## TL;DR

- We don't sell or rent any data.
- We don't show ads.
- We don't use IDFA. The IDFA-capable Firebase SDK is not in the binary.
- There is no ATT (App Tracking Transparency) prompt because there's nothing to track.
- Your private notes, custom events, and bookmarks live in your iCloud private database. We don't have the key.

## What we collect

**Conference data** — talks, events, speakers, maps, merch, news. Read from Firebase Firestore. We never write anything to your account; data flows one direction, server → your phone.

**Your bookmarks, custom events, and private notes** — stored in local Core Data on your device, optionally synced via *your* iCloud private database. We don't have the key. We never see them.

**Crash reports** — stack traces and the OS / app version when the app crashes. Sent to Firebase Crashlytics on the next launch after a crash. No message bodies, no user input, no IDFA. Sent only when the app crashes; nothing is sent during normal use.

**Push notification token** — the opaque APNs identifier Apple gives the app for delivering pushes. Stored in Firebase Cloud Messaging so we can send conference-wide announcements you opted into via iOS Settings. Deleting the app or revoking notification permission cuts this off immediately.

**Anonymous usage events** — which screens you visit, how long the session was, the app version, the device model and OS version. Stored in Firebase Analytics (the **no-IDFA** variant — we link the build of the SDK that literally cannot read the advertising identifier). No name, no email, no IDFA, no cross-app tracking. Used to tell us which parts of the app are actually used so we can prioritize fixes and features.

## What we don't collect

- Your name, email, account, or phone number. We don't have user accounts.
- Your contact list, photos, microphone, camera, or precise location.
- Browsing history, ad identifiers (IDFA), or device fingerprints. We link the no-AdId build of Firebase Analytics; the IDFA-capable variant is **not present in the app bundle**.
- The contents of your bookmarks, custom events, or private notes — those live in your iCloud private database, encrypted; we have no access to them.
- Tracking across other apps or websites. There is no ATT prompt because there is no IDFA to collect.

## Your choices

**Disable notifications.** *Settings → Notifications → HackerTracker → off.* We can no longer push you anything.

**Delete your local data.** Swipe-delete bookmarks, long-press to delete custom events / notes from inside the app. Or sign out of iCloud, or uninstall the app — your local store goes with it.

## What we never do

- Sell or rent any data to anyone, ever.
- Show ads.
- Share identifiers with ad networks, marketing platforms, or data brokers.
- Read your private notes, custom events, or bookmark contents. CloudKit puts those in your private database, encrypted; we don't have the key.

## What CloudKit does for you

Your bookmarks, custom events, and private notes are stored in **Core Data** locally and replicated to **your Apple ID's iCloud private database** via `NSPersistentCloudKitContainer`.

Properties of this storage:
- **End-to-end encrypted** when iCloud Advanced Data Protection is enabled on your Apple ID.
- **Sandboxed per Apple ID** — only your devices have access.
- **Off-limits to us** — the app's developers have no read access. We can't make this point strongly enough.

## App Store privacy disclosures

The corresponding **App Store Connect → Privacy** disclosures for this app:

| Data type | Linked to user? | Used for tracking? | Purposes |
|---|---|---|---|
| Crash Data | No | No | App Functionality |
| Performance Data | No | No | Analytics, App Functionality |
| Other Diagnostic Data | No | No | Analytics, App Functionality |
| Product Interaction | No | No | Analytics, App Functionality |
| Push Notification Token | No | No | App Functionality |

(No **Device ID (IDFA)** disclosure because we don't collect it.)

## Contact

Questions? Bugs? Privacy concerns? Email **hackertracker@defcon.org** or [open an issue](https://github.com/junctor/hackertracker-ios/issues/new). We respond.

## Source of truth

The in-app version of this disclosure lives at [`hackertracker/Views/PrivacyDoc.swift`](../hackertracker/Views/PrivacyDoc.swift) and is rendered under **Settings → Privacy & Tracking**. When this page changes, that file changes — or the other way around. The two must agree.
