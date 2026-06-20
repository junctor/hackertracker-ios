# Combined Bookmark Schedule

Cross-conference timeline of just your bookmarks. Appears automatically when the timing makes sense.

## When it shows up

The **Combined Schedule** card appears on the **Info** tab (home screen) only when **both** are true:

1. You have **2+ conferences with overlapping dates** loaded into the app.
2. You have **bookmarks in at least 2 of the overlapping conferences**.

The classic case: DEF CON, BSidesLV, and Black Hat all running the same week in Las Vegas. Bookmark talks in two or all three, and the card appears.

## What you see

Tap the card to open a single day-grouped timeline showing every bookmarked event from all qualifying conferences. Each row carries a **conference badge** (tinted to that conference's accent color) so you can tell where each event lives.

Times are rendered in **your device's local timezone** — so if conferences span timezones (rare) or you're remote, the wall-clock times are sensible.

## Limitations

- **Event IDs aren't globally unique across conferences** in the underlying Firestore data. In the unlikely case of a collision, both events appear; the conference badge disambiguates.
- **Speaker names aren't shown** in this view. Cross-conference speaker lookup adds complexity for marginal benefit; the title + conference badge + time identify each entry clearly.

## What it doesn't do

It doesn't let you bookmark from this screen — that happens in each conference's own Schedule. It doesn't sync some new flavor of "global bookmark" to iCloud — it's a derived view of bookmarks that already sync.

## Removing it

Remove all bookmarks from one of the contributing conferences. On next refresh (returning to InfoView triggers it), the card disappears.

## See also

- [Bookmarking events](bookmarks.md)
- [Schedule view](schedule.md)
