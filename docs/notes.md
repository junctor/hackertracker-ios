# Private notes

Markdown-formatted notes attached to any event, talk, or custom event. Stored locally and synced via your iCloud private database.

## Adding a note

On any detail screen — an event, talk, or custom event — scroll to the bottom. You'll see a collapsed section labeled **My Notes**:

```
📝  My Notes                                              Show ›
```

Tap the row to expand. The accent dot appears when there's already a note saved; absent dot = empty.

If empty:
- An **Add a note** button appears.
- Tap it to open the editor.

If a note exists:
- Markdown render of your note is shown read-only.
- Tap anywhere on the rendered text to open the editor.

## The editor

The editor sheet has two tabs:

- **Write** — a monospace `TextEditor` for entering Markdown.
- **Preview** — same editor body rendered as Markdown.

Supports the standard Markdown syntax: headings, bold/italic, lists, links, code blocks, etc. (Same `MarkdownUI` library used for the conference's content descriptions.)

Toolbar:
- **Cancel** — discard the in-progress edit.
- **🗑 (trash, destructive)** — only visible when editing an existing note. Confirms before deleting; deletion propagates to your iCloud-synced devices.
- **Save** — persist the note.

## Where notes live

Notes are stored as Core Data rows keyed by `(targetID, targetKind)`. The kind is one of `event`, `content`, or `customEvent`. They're synced to your **iCloud private database** via `NSPersistentCloudKitContainer`.

We never see them. There's no server-side storage of note content.

If you uninstall the app and reinstall without signing into iCloud, the notes are gone. With iCloud signed in, they come back.

## Cross-kind notes

You can author a note from either the **Schedule** detail screen (kind = `event`) or the **All Content** detail screen (kind = `content`). The app cross-references both:

- A note authored from a talk's detail lights up the **pencil badge** on both the Schedule row for any session of that talk AND the All Content row for the talk itself.
- The **Has Notes** filter on either list catches the same set of events.

You're never forced to remember "where did I add that note" — it just shows up.

## Find rows with notes

Each list row shows a **pencil icon** to the left of the bookmark when the row's target has a saved note. The filter sheet's **Has Notes** chip narrows the list to just those rows.

## Limits

- **One note per item.** Editing replaces the previous body.
- **No images or attachments.** Markdown text only.
- **Empty notes are auto-deleted.** Saving a blank or whitespace-only body removes the row. The CTA reverts to "Add a note."

## See also

- [Bookmarking events](bookmarks.md)
- [Custom events](custom-events.md)
- [Search and filter](search-and-filter.md)
