# Screenshot capture guide

How to capture the screenshots referenced by the user guide pages.

## File naming

All filenames are lowercase-hyphenated, end in `.png`, and land in `docs/images/`. The docs pages reference them with relative paths (`images/foo.png`).

## Recommended capture setup

- **iPhone screenshots** — iPhone 16 (Apple Silicon simulator) portrait orientation. 1290×2796 native; GitHub will scale.
- **iPad screenshots** — iPad Pro 11" (M4) landscape orientation. 1668×2388 native.
- Use a real-data conference (DEFCON33 or whatever's currently loaded) — empty-state mocks make the guide misleading.
- Light or dark mode is fine; pick one and stick with it for visual consistency. (Dark mode is the app's default.)
- Hide the simulator's status bar if you can: `xcrun simctl status_bar booted override --time "9:41" --batteryState charged --batteryLevel 100`

## Capture command

In Simulator with your screen visible:

```sh
xcrun simctl io booted screenshot docs/images/<filename>.png
```

Or use the Simulator menu: **File → New Screen Shot** (saves to Desktop), then drag into `docs/images/`.

## The list

Each row: filename, what it shows, suggested device, suggested in-app state.

### Home & navigation

| Filename | Shows | Device | State |
|---|---|---|---|
| `home-iphone.png` | InfoView top half — banner, news card, feature grid | iPhone | A conference loaded with news + cards visible |
| `tab-bar.png` | Bottom tab bar close-up (just the bar, cropped) | iPhone | Any tab selected — Schedule tab is most representative |

### Schedule (`schedule.md`)

| Filename | Shows | Device | State |
|---|---|---|---|
| `schedule-iphone.png` | Schedule tab with a day of events visible | iPhone | A few bookmarked events to show the filled/outline mix |
| `schedule-row.png` | Close-up of a single event row | iPhone | A row that includes a stripe, speakers, location, tag chips, pencil icon (saved note), and bookmark |
| `schedule-floating-controls.png` | Bottom-left filter circle + bottom-right Top/Bottom jump menu | iPhone | Scroll to a position where both are visible |

### Bookmarks (`bookmarks.md`)

| Filename | Shows | Device | State |
|---|---|---|---|
| `bookmark-toggle.png` | Side-by-side outline + filled bookmark on two adjacent rows | iPhone | One bookmarked event + one unbookmarked event |
| `bookmark-conflict.png` | A red (conflict) bookmark icon + the toolbar's red triangle warning | iPhone | Two overlapping events bookmarked |
| `share-schedule-qr.png` | Share Schedule sheet showing a QR code | iPhone | Trigger from Schedule toolbar → menu → Share Schedule |

### Combined Schedule (`combined-schedule.md`)

| Filename | Shows | Device | State |
|---|---|---|---|
| `combined-schedule-card.png` | The Combined Schedule card on the Info tab | iPhone | Need 2+ overlapping conferences with bookmarks in each |
| `combined-schedule-view.png` | Tap-through view showing cross-conference timeline with conference badges | iPhone | Same setup |

### Custom Events (`custom-events.md`)

| Filename | Shows | Device | State |
|---|---|---|---|
| `custom-event-form.png` | The create form — title, when, where, description, color, conferences | iPhone | Tap + on Schedule, fill some fields, screenshot before saving |
| `custom-event-row.png` | A custom event in the Schedule with stripe + "Custom Event" chip | iPhone | After saving one |
| `custom-event-detail.png` | Custom event detail screen showing toolbar (bookmark / bell / QR / pencil) | iPhone | Tap a custom event row |
| `custom-event-qr.png` | The QR share sheet for a custom event | iPhone | Tap the QR toolbar button on the detail screen |

### Notes (`notes.md`)

| Filename | Shows | Device | State |
|---|---|---|---|
| `note-collapsed.png` | The "My Notes" row collapsed with the accent dot indicating saved content | iPhone | Have a note saved on the current event, scroll to bottom |
| `note-expanded.png` | Expanded note showing Markdown render | iPhone | Same event, tap Show |
| `note-editor.png` | The Note Editor sheet on the Write tab | iPhone | Tap the note to edit |

### Maps (`maps.md`)

| Filename | Shows | Device | State |
|---|---|---|---|
| `maps-iphone.png` | A loaded map with the floating zoom pill | iPhone | DEF CON map or similar |
| `maps-search.png` | The SVG search field active with a highlighted result | iPhone | Requires an SVG-published conference; type a room number |
| `maps-empty.png` | Bobbing Beezle empty state on first load | iPhone | Wipe the simulator, fresh install, immediately open Maps |

### Search and filter (`search-and-filter.md`)

| Filename | Shows | Device | State |
|---|---|---|---|
| `filter-sheet.png` | The full filter sheet with chips and tally visible | iPhone | Open from Schedule, select 2-3 chips so the tally has a number to show |
| `filter-match-mode.png` | Close-up of the Match Any/All segmented picker + the live tally row | iPhone | Same — focus the screenshot on the picker area |

### AI summaries (`ai-summaries.md`)

| Filename | Shows | Device | State |
|---|---|---|---|
| `ai-summary-row.png` | A Schedule row with the sparkle ✨ + AI summary line below the speaker name | iPhone | iOS 26 device with AI Summaries enabled; let summaries generate |
| `ai-summary-toggle.png` | Settings → AI Summaries toggle row | iPhone (iOS 26+ where toggle appears) | Just open Settings |

### Privacy (`privacy.md`)

| Filename | Shows | Device | State |
|---|---|---|---|
| `privacy-settings-row.png` | The Privacy & Tracking row in Settings | iPhone | Settings tab |
| `privacy-doc.png` | The Privacy doc rendered (DocumentView) | iPhone | Tap the row |

### iPad layout (`ipad.md`)

| Filename | Shows | Device | State |
|---|---|---|---|
| `schedule-ipad.png` | iPad Schedule split view: sidebar list + detail pane | iPad landscape | Tap a row so the detail pane is populated |
| `settings-ipad.png` | iPad two-column Settings | iPad landscape | Open Settings |

### Easter eggs (`easter-eggs.md`)

| Filename | Shows | Device | State |
|---|---|---|---|
| `easter-egg-watermark.png` | The Beezle ghost watermark visible behind the UI | iPhone | Settings → Easter Eggs on, set opacity to 0.40 temporarily so it shows in the screenshot |
| `easter-eggs-enabled.png` | The "Easter Eggs Enabled" overlay after 7-tap chord | iPhone | Tap version label 7× on InfoView, screenshot before the overlay dismisses |

---

## Total

28 screenshots. Plan ~45 minutes if you've got the app in the right state already.

## Next step after capture

Once all (or most) of the files are in `docs/images/`, ping the docs maintainer to verify file presence and merge. The user-guide pages already reference these filenames — pushing the files alone makes the pages light up.

## What if I'm missing some?

Push what you have. Missing images render as broken-image icons on GitHub, which serves as a visible TODO. You can fill in later.
