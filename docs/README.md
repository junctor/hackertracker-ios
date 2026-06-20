# HackerTracker iOS — User Guide

The official guide to using HackerTracker on iPhone and iPad. Covers everyday use, every feature, the iPad-specific layout, and how your data is handled.

If you're looking for the **5-minute version**, start with [Quick Start](quickstart.md).

---

## Contents

### Getting around
- [Quick Start](quickstart.md) — install, pick a conference, see your first schedule
- [Tabs and navigation](navigation.md) — the four tabs and what each one does
- [Schedule view](schedule.md) — the main agenda
- [iPad-specific layout](ipad.md) — split view, two-column Settings, two-up Maps

### Personal data
- [Bookmarking events](bookmarks.md) — saving talks you want to attend
- [Combined Bookmark Schedule](combined-schedule.md) — cross-conference timeline of just your saved events
- [Private notes](notes.md) — Markdown notes on any event or talk
- [Custom events](custom-events.md) — your own schedule entries, multi-conference, sharable via QR

### Discovery
- [Search and filter](search-and-filter.md) — finding talks, tags, the Any/All match toggle
- [AI summaries](ai-summaries.md) — on-device summaries on iOS 26+
- [Maps](maps.md) — venue floor plans, search, share

### Other
- [Privacy and tracking](privacy.md) — what we collect, what we don't
- [Easter eggs](easter-eggs.md) — there is one. See if you can find it.
- [Troubleshooting](troubleshooting.md) — common problems and fixes

---

## What's new in 6.0

Highlights from this release. The full changelog is below; for the in-app version, **Settings → About**.

**Major new features**
- **Custom events** — create your own schedule entries, sync via iCloud, share by QR code.
- **Private notes** on any event, talk, or custom event. Markdown-formatted, iCloud-synced.
- **On-device AI summaries** of talk descriptions (iOS 26+ with Apple Intelligence).
- **Combined Bookmark Schedule** — cross-conference timeline when bookmarks overlap.
- **Searchable SVG maps** when the conference publishes them.

**iPad overhaul**
- Split view across Schedule, All Content, Speakers, Communities, Merch — same 500pt sidebar across all of them.
- Two-column Settings.
- Two-up landscape mode on Maps.

**Filters**
- Match Any / Match All segmented toggle on every filter sheet.
- Live count of matching items shown under the picker.
- New chips: Bookmarks, Custom Events, Has Notes.

**Privacy**
- No ATT prompt — we no longer link the IDFA-capable Firebase SDK.
- Settings → Privacy & Tracking screen with full disclosure.

**Performance**
- O(1) speaker/location/tag lookups.
- Schedule swipe and search debounced.
- Map PDFs pre-warmed into a cache on conference load.

---

## Need help?

- **Open an issue**: [github.com/junctor/hackertracker-ios/issues](https://github.com/junctor/hackertracker-ios/issues)
- **Email**: hackertracker@defcon.org

---

*This guide tracks the app's actual behavior at the time of writing. Each page links to the source file when relevant so you can verify or contribute fixes. If something here doesn't match what you see in the app, [open an issue](https://github.com/junctor/hackertracker-ios/issues/new).*
