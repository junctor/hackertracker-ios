# Report-an-Issue (Content Feedback) — Design Spec

**Date:** 2026-07-20
**Status:** Approved for planning
**Feature branch:** `feature/filters-and-feedback`

## Summary

Let users report a piece of content back to the developers from the detail screens. A
"Report an issue" toolbar action opens a sheet with a free-text message; sending POSTs a
JSON payload to `https://feedback1.junctorconf.net/reporting.php`. Privacy-preserving:
only the user's message and an anonymous, app-generated install identifier leave the device.

## Decisions

| # | Decision | Choice |
|---|----------|--------|
| 1 | `device_identifier` | **App-generated random UUID**, created once and stored in the Keychain; not device/IDFV-derived. |
| 2 | Placement | **Toolbar "Report an issue" item** on each detail screen → modal sheet with a message field. |
| 3 | object_type mapping | event/content → `content`, speaker → `person`, org → `org`, document → `document`. |
| 4 | `report_timestamp` | `"yyyy-MM-dd HH:mm:ss"` in **UTC**. |
| 5 | `report_uuid` | Fresh `UUID()` per report. |
| 6 | `client` | `"HackerTracker iOS <marketingVersion> (<build>)"`. |

## Endpoint & payload

`POST https://feedback1.junctorconf.net/reporting.php`, `Content-Type: application/json`:

```json
{
  "message": "<user free text>",
  "conference_id": 258,
  "conference_name": "DEF CON 34",
  "object_type": "content",
  "object_id": 0,
  "report_timestamp": "2026-01-02 23:45:59",
  "report_uuid": "1B2A3695-7D25-412F-B442-CF9094E1B6B8",
  "client": "HackerTracker iOS 6.2 (26072001)",
  "device_identifier": "<persisted install UUID>"
}
```

- `conference_id` (Int) / `conference_name` — from `InfoViewModel.conference` (`id: Int`, `name`).
- `object_type` / `object_id` — supplied by the calling detail screen.
- `report_timestamp` — a `DateFormatter` with `yyyy-MM-dd HH:mm:ss`, `TimeZone(identifier: "UTC")`, `Locale(identifier: "en_US_POSIX")`.
- `client` — `CFBundleShortVersionString` + `CFBundleVersion`.

## Design

### 1. `DeviceIdentifier` (Keychain-backed install UUID)

```swift
enum ReportDeviceIdentifier {
    /// Random UUID generated once and stored in the Keychain (survives app
    /// reinstall on the same device/keychain; not derived from the device).
    static func current() -> String
}
```
On first call, generate `UUID().uuidString`, store under a fixed Keychain key, return it;
subsequent calls read it back. This is anonymous and not cross-app — consistent with the
app's no-tracking / no-IDFA posture.

### 2. `FeedbackReporter` (service)

```swift
enum ReportObjectType: String { case content, org, person, document }

struct FeedbackReport: Encodable {
    let message: String
    let conferenceId: Int
    let conferenceName: String
    let objectType: String          // ReportObjectType.rawValue
    let objectId: Int
    let reportTimestamp: String      // UTC "yyyy-MM-dd HH:mm:ss"
    let reportUuid: String
    let client: String
    let deviceIdentifier: String
    // CodingKeys map to snake_case exactly per the payload above.
}

enum FeedbackReporter {
    /// Builds the payload (stamping timestamp/uuid/client/device id) and
    /// POSTs it. Returns success or a user-presentable failure.
    static func send(message: String,
                     conference: Conference,
                     objectType: ReportObjectType,
                     objectId: Int) async -> Result<Void, ReportError>
}
```
- Endpoint URL is a single constant.
- Timestamp/uuid/client/device-id are stamped inside `send` (injectable in tests via
  a small internal builder so payload construction is testable without the network).
- Non-2xx or transport error → `.failure(ReportError)` with a friendly message.

### 3. `ReportContentSheet` (UI)

A modal sheet: title, a short "Please don't include personal information" caption, a
`TextEditor` bound to the message, and Cancel / Send. Send is disabled while empty or
in flight; shows a spinner; on success dismisses with a brief confirmation; on failure
shows an alert with Retry. Styled with the existing `themeManager` fonts/`settingsCard`
conventions.

### 4. Wiring

Add a **"Report an issue"** toolbar item (in the existing ⋯/options menu where present,
else a dedicated toolbar button) that presents `ReportContentSheet` with the right
`objectType`/`objectId` on:
- `ContentDetailView` → `.content`, `content.id` (events route here).
- `SpeakerDetailView` → `.person`, `speaker.id`.
- `OrgView` → `.org`. `Organization.id` is a `@DocumentID String?` — there is **no Int
  identity** for an organization — so send `object_id: 0` (matching the sample payload's
  `"object_id": 0`); the report is identified by `object_type` + `conference_id` + the
  message text. (If the server later needs to pin the exact org, we'd add a string id
  field server-side; out of scope here.)
- `DocumentView` → `.document`, `document.id`.

## Error handling

- All failures fold into a single `ReportError` with a user-facing string; the sheet shows
  an alert with Retry and stays open so the message isn't lost.
- No offline queue / retry-later (out of scope) — the user simply retries.

## Testing

- Unit-test payload construction: given fixed message/conference/objectType/objectId and an
  injected timestamp + uuid + device id, assert the encoded JSON has the exact snake_case
  keys and values (`object_type`, `report_timestamp` format, `client` string).
- Unit-test `ReportDeviceIdentifier.current()` returns a stable value across calls.
- The live network POST is integration/manual (verify a 2xx against the real endpoint from
  a build); not unit-tested.

## Non-goals

- No server-side changes, no rate limiting, no attachments/screenshots, no categories/reason
  codes (free text only), no offline queue, no auth. Message + anonymous install id only.
