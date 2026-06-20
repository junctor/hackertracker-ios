# Custom events

Create your own schedule entries that show up alongside the official conference program.

Custom events are perfect for:
- Coffee with a specific person at 11am.
- A meetup at a particular bar Friday night.
- A reminder about a workshop you signed up for outside the official schedule.

## Creating one

1. Open the **Schedule** tab (calendar icon).
2. Tap the **+** in the top-right of the toolbar.
3. Fill in the form. **Title**, **Starts**, and **Ends** are required.
4. **Save**.

Your event appears immediately in the Schedule, sorted into the right time slot.

## Form fields

- **Title** — what to call it. Required.
- **Starts / Ends** — DatePickers. End can't precede start.
- **Where** — free-text location.
- **Description** — Markdown-supported, multi-line.
- **Appearance → Accent color** — picks the colored stripe on the left side of the schedule row.
- **Send a notification before this event** — uses the global "Before Event" minutes from Settings. **Off by default** — flip it on per event when you want a reminder.
- **Applies to** — one or more conferences. Defaults to the currently-selected one. Pick none to make the event show on every conference's schedule (a "personal recurring" event).

## Visual indicators

A custom event row carries:
- Your chosen **accent color** as the left stripe (instead of the conference tag color).
- A small **"Custom Event"** chip in the tag area.
- A **pencil** to its left if it also has a [private note](notes.md).
- The same bookmark icon as normal events (though custom events show in your schedule unconditionally, regardless of bookmark state).

## Editing or deleting

Tap a custom event row to open its detail view. The toolbar has:

| Icon | Action |
|---|---|
| **Bookmark** | Toggle bookmark (mostly cosmetic for custom events; useful when you filter by Bookmarks) |
| **Bell** | Toggle notifications on/off. One-tap, no edit form required. |
| **QR code** | Open the share sheet to give this event to someone else (see below) |
| **Pencil** | Open the form in edit mode |

Inside the form, edit mode adds a destructive **Delete event** row at the bottom with a confirmation dialog.

## Sharing a custom event via QR code

Each custom event detail screen has a **QR code** icon in the toolbar.

1. Tap it to present the share sheet.
2. The sheet shows a QR code on a white card (so dark-mode themes can't garble it).
3. Recipient opens **iOS Camera** and points it at the QR code, OR you can tap **Share Link…** to AirDrop or copy the URL.
4. The recipient's phone opens HackerTracker with the form **pre-filled**: title, time, location, description, color, conferences, notifications setting.
5. They tap **Save** to add it to their own device.

The URL format is `hackertracker://import/customEvent?t=…&b=…&e=…` — see [Tabs and navigation](navigation.md) for the full deep-link reference. **Notes are intentionally not shared** — they're a private journal field, not part of the event's public identity.

## Multi-conference attachment

Custom events store a list of **conference codes** they apply to:

- Empty list → applies to every conference.
- One or more codes → only shows on those conferences' schedules.

This is one event row, not duplicated copies. Edit it once and the changes appear across all attached conferences.

## Privacy and sync

Custom events live in Core Data backed by **NSPersistentCloudKitContainer**. They sync to your iCloud private database (assuming you're signed in) and propagate across your devices automatically.

We never see them — Apple's CloudKit puts them in your private storage; we don't have the key.

## Filtering and hiding

The filter sheet has a **Custom Events** chip — selecting it narrows the schedule to user-created rows only.

To hide custom events from the schedule entirely without deleting them, **Settings → Custom Events on Schedule** off. The local data is untouched.

## See also

- [Schedule view](schedule.md)
- [Private notes](notes.md)
- [Search and filter](search-and-filter.md)
