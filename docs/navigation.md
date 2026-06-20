# Tabs and navigation

The HackerTracker tab bar has four tabs. Each tab is independent — switching tabs doesn't lose your place inside another tab.

## Info (house icon)

The home screen. Shows:
- The conference banner, name, and tagline.
- A **News** card with the most recent article (toggle off in Settings if you'd rather not see it).
- A grid of feature cards: **Schedule**, **All Content** (talks list), **Speakers**, **Communities/Villages**, **Locations**, **FAQ**, **Merch**, **Shared Schedule**, **Emergency Info**, **About**, and conference-specific menus.
- Beneath the grid, a version label at the bottom — tap it seven times for an [Easter Egg](easter-eggs.md).

## Schedule (calendar icon)

The day-by-day agenda. See [Schedule view](schedule.md).

## Maps (map icon)

The venue floor plans. See [Maps](maps.md).

## Settings (gear icon)

App preferences: select conference, theme, time format, notification offset, and feature toggles. See the individual feature pages for the relevant Settings entries.

## Returning to the top of a list

Most list screens (Schedule, All Content, Speakers, Orgs, Merch) have a **Top / Bottom** jump menu in the lower-right corner. Useful in long conferences.

## Conference switching

**Settings → Select Conference** opens the conferences list. Active conferences (current or upcoming) appear at the top; past conferences are below.

Switching conferences re-fetches the schedule, content, speakers, maps, and tags. Your bookmarks, custom events, and private notes stay with you across switches (they're tagged with conference codes when relevant, but the storage is global).

## Deep links

HackerTracker registers the `hackertracker://` URL scheme:

| URL | Effect |
|---|---|
| `hackertracker://DEFCON33` | Switch to DEFCON33 if available |
| `hackertracker://DEFCON33/content?id=42` | Open All Content → talk 42 |
| `hackertracker://DEFCON33/event?id=42` | Resolve event 42 to its parent talk, then open it |
| `hackertracker://DEFCON33/s?ids=1,2,3` | Open a Shared Schedule view of those bookmark ids |
| `hackertracker://import/customEvent?t=…&b=…&e=…` | Import a [custom event](custom-events.md) from a scanned QR code |
| `hackertracker://DEFCON33/404` | (Debug) present the empty-state ghost screen |

Useful for sharing direct links to specific talks or for the custom-event QR import.
