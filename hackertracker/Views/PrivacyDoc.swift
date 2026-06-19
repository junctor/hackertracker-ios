//
//  PrivacyDoc.swift
//  hackertracker
//
//  User-facing privacy + tracking disclosure. Surfaced via
//  PrivacySettingsView under Settings → About so users can read it
//  any time, and used as the source of truth for App Store Connect's
//  Privacy section + the in-system ATT prompt copy.
//
//  Keep this concise and concrete: this audience reads carefully.
//

import Foundation

enum PrivacyDoc {
    static let title = "Privacy & Tracking"

    static let body = """
# How HackerTracker uses your data

HackerTracker is built for the DEF CON / hacker conference audience. We take \
\"the security people are watching\" personally — here's exactly what data the \
app touches, why, and what stays on your device.

## What we collect

**Conference data** — talks, events, speakers, maps, merch, news. Read from \
Firebase Firestore. We never write anything to your account; the data flows \
one direction, server to your phone.

**Your bookmarks, custom events, and private notes** — stored in local Core \
Data on your device, optionally synced via *your* iCloud private database. \
We don't have the key. We never see them.

**Crash reports** — stack traces and the OS / app version when the app \
crashes. Sent to Firebase Crashlytics on the next launch after a crash. \
No message bodies, no user input, no IDFA. Sent only when the app crashes; \
nothing is sent during normal use.

**Push notification token** — the opaque APNs identifier Apple gives the app \
for delivering pushes. Stored in Firebase Cloud Messaging so we can send \
conference-wide announcements you opted into via iOS Settings. Deleting the \
app or revoking notification permission cuts this off immediately.

**Anonymous usage events** (only with your permission) — which screens you \
visit, how long the session was, the app version, the device model and OS \
version. Stored in Firebase Analytics. **No name, no email, no IDFA unless \
you grant ATT permission.** Used to tell us which parts of the app are \
actually used so we can prioritize fixes and features.

## What we **don't** collect

- Your name, email, account, or phone number. We don't have user accounts.
- Your contact list, photos, microphone, camera, or precise location.
- Browsing history, ad identifiers (unless you explicitly grant ATT \
permission), or device fingerprints.
- The contents of your bookmarks, custom events, or private notes — those \
live in your iCloud private database, encrypted; we have no access to them.
- Tracking across other apps or websites. The ATT prompt's *Allow* option \
enables IDFA for in-app session analytics only; it does **not** opt you \
into cross-app tracking, ad networks, or third-party data sharing.

## Your choices

**Decline tracking at the prompt.** Tap *Ask App Not to Track* the first \
time the app asks. We still receive aggregate analytics (no IDFA) and \
crashes; you receive nothing different on screen.

**Disable analytics later.** *Settings → iPhone → Privacy & Security → \
Tracking → toggle HackerTracker off.* The app stops receiving IDFA-linked \
analytics immediately.

**Disable notifications.** *Settings → Notifications → HackerTracker → off.* \
We can no longer push you anything.

**Delete your local data.** Swipe-delete bookmarks, long-press to delete \
custom events / notes from inside the app. Or sign out of iCloud, or \
uninstall the app — your local store goes with it.

## What we never do

- Sell or rent any data to anyone, ever.
- Show ads.
- Share identifiers with ad networks, marketing platforms, or data brokers.
- Read your private notes, custom events, or bookmark contents. CloudKit \
puts those in your private database, encrypted; we don't have the key.

## Contact

Questions? Bugs? Privacy concerns? Email \
[hackertracker@defcon.org](mailto:hackertracker@defcon.org) or open an \
issue on the [repository](https://github.com/junctor/hackertracker-ios). \
We respond.
"""
}
