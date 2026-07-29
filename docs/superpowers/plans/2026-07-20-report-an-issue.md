# Report-an-Issue (Content Feedback) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let users report a piece of content to the developers from the detail screens via a POST to the feedback endpoint.

**Architecture:** A `FeedbackReporter` service builds the exact JSON payload (stamping a UTC timestamp, per-report UUID, client string, and an anonymous Keychain install id) and POSTs it; a `ReportContentSheet` collects the message; a toolbar "Report an issue" item on each detail screen presents it with the right `object_type`/`object_id`.

**Tech Stack:** Swift 6, SwiftUI, URLSession, Security (Keychain), XCTest.

## Global Constraints

- Deployment target stays iOS 17.0.
- Endpoint: `POST https://feedback1.junctorconf.net/reporting.php`, `Content-Type: application/json`.
- Payload keys (snake_case, exact): `message`, `conference_id` (Int), `conference_name`, `object_type` (one of `content`/`org`/`person`/`document`), `object_id` (Int), `report_timestamp` (`"yyyy-MM-dd HH:mm:ss"`, **UTC**, `en_US_POSIX`), `report_uuid` (fresh per report), `client` (`"HackerTracker iOS <marketingVersion> (<build>)"`), `device_identifier` (anonymous Keychain install UUID).
- `object_type` mapping: content/event → `content`, speaker → `person`, org → `org`, document → `document`. Orgs send `object_id: 0` (no Int identity).
- Only the message + anonymous install id leave the device (no tracking/PII).
- New source files need manual `project.pbxproj` wiring. Tests append to `hackertrackerTests/hackertrackerTests.swift`.
- Build: `xcodebuild -project hackertracker.xcodeproj -scheme hackertracker -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.2' build`; Test: same with `test`.

---

### Task 1: `FeedbackReporter` service (payload, device id, POST)

**Files:**
- Create: `hackertracker/Utils/FeedbackReporter.swift`
- Modify: `hackertracker.xcodeproj/project.pbxproj`
- Test: `hackertrackerTests/hackertrackerTests.swift`

**Interfaces:**
- Produces:
  - `enum ReportObjectType: String { case content, org, person, document }`
  - `struct FeedbackReport: Encodable` (snake_case CodingKeys per the payload).
  - `enum ReportDeviceIdentifier { static func current() -> String }`
  - `enum FeedbackReporter { static func makeReport(message:conference:objectType:objectId:now:uuid:deviceID:) -> FeedbackReport; static func send(message:conference:objectType:objectId:) async -> Result<Void, ReportError> }`
  - `struct ReportError: Error { let message: String }`

- [ ] **Step 1: Failing tests** — append. These test the deterministic payload builder (no network) and encoding:

```swift
func testFeedbackReportEncodesExactKeys() throws {
    let conf = Conference.reportStub(id: 258, name: "DEF CON 34")   // add stub below
    let fixedDate = Date(timeIntervalSince1970: 1_767_400_000)       // deterministic
    let report = FeedbackReporter.makeReport(
        message: "nope", conference: conf, objectType: .person, objectId: 42,
        now: fixedDate, uuid: "UUID-1", deviceID: "DEV-1")
    let data = try JSONEncoder().encode(report)
    let obj = try JSONSerialization.jsonObject(with: data) as! [String: Any]
    XCTAssertEqual(obj["conference_id"] as? Int, 258)
    XCTAssertEqual(obj["object_type"] as? String, "person")
    XCTAssertEqual(obj["object_id"] as? Int, 42)
    XCTAssertEqual(obj["report_uuid"] as? String, "UUID-1")
    XCTAssertEqual(obj["device_identifier"] as? String, "DEV-1")
    XCTAssertNotNil(obj["report_timestamp"] as? String)
    XCTAssertTrue((obj["client"] as? String)?.hasPrefix("HackerTracker iOS") ?? false)
    // UTC "yyyy-MM-dd HH:mm:ss" shape
    XCTAssertEqual((obj["report_timestamp"] as? String)?.count, 19)
}
func testDeviceIdentifierIsStable() {
    XCTAssertEqual(ReportDeviceIdentifier.current(), ReportDeviceIdentifier.current())
}
```

Add a `Conference.reportStub` helper at the bottom of the test file — check `Models/Conference.swift` for the member-wise initializer and fill all stored properties (id, name, code, dates, timestamps, hidden, enableMerch, enableMerchCart, homeMenuId, and the optionals as nil). If the initializer is large, prefer decoding a minimal JSON fixture instead.

- [ ] **Step 2: Run — expect FAIL** (`cannot find 'FeedbackReporter'`).

- [ ] **Step 3: Implement** — `hackertracker/Utils/FeedbackReporter.swift`:

```swift
import Foundation
import Security

enum ReportObjectType: String { case content, org, person, document }

struct ReportError: Error { let message: String }

struct FeedbackReport: Encodable {
    let message: String
    let conferenceId: Int
    let conferenceName: String
    let objectType: String
    let objectId: Int
    let reportTimestamp: String
    let reportUuid: String
    let client: String
    let deviceIdentifier: String

    enum CodingKeys: String, CodingKey {
        case message
        case conferenceId = "conference_id"
        case conferenceName = "conference_name"
        case objectType = "object_type"
        case objectId = "object_id"
        case reportTimestamp = "report_timestamp"
        case reportUuid = "report_uuid"
        case client = "client"
        case deviceIdentifier = "device_identifier"
    }
}

/// Anonymous, app-generated install identifier. Random UUID created once
/// and stored in the Keychain (not device/IDFV-derived) — no tracking.
enum ReportDeviceIdentifier {
    private static let account = "org.beezle.hackertracker.reportDeviceID"

    static func current() -> String {
        if let existing = read() { return existing }
        let new = UUID().uuidString
        save(new)
        return new
    }

    private static func read() -> String? {
        let q: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var out: AnyObject?
        guard SecItemCopyMatching(q as CFDictionary, &out) == errSecSuccess,
              let data = out as? Data, let s = String(data: data, encoding: .utf8) else { return nil }
        return s
    }

    private static func save(_ value: String) {
        let data = Data(value.utf8)
        let q: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        SecItemDelete(q as CFDictionary)
        SecItemAdd(q as CFDictionary, nil)
    }
}

enum FeedbackReporter {
    private static let endpoint = URL(string: "https://feedback1.junctorconf.net/reporting.php")!

    private static let timestampFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return f
    }()

    static func clientString() -> String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "HackerTracker iOS \(v) (\(b))"
    }

    /// Deterministic builder (injectable stamps for tests).
    static func makeReport(message: String, conference: Conference,
                           objectType: ReportObjectType, objectId: Int,
                           now: Date, uuid: String, deviceID: String) -> FeedbackReport {
        FeedbackReport(
            message: message,
            conferenceId: conference.id,
            conferenceName: conference.name,
            objectType: objectType.rawValue,
            objectId: objectId,
            reportTimestamp: timestampFormatter.string(from: now),
            reportUuid: uuid,
            client: clientString(),
            deviceIdentifier: deviceID
        )
    }

    static func send(message: String, conference: Conference,
                     objectType: ReportObjectType, objectId: Int) async -> Result<Void, ReportError> {
        let report = makeReport(message: message, conference: conference,
                                objectType: objectType, objectId: objectId,
                                now: Date(), uuid: UUID().uuidString,
                                deviceID: ReportDeviceIdentifier.current())
        do {
            var req = URLRequest(url: endpoint)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONEncoder().encode(report)
            let (_, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                Log.network.error("feedback POST non-2xx")
                return .failure(ReportError(message: "The report couldn’t be sent. Please try again."))
            }
            return .success(())
        } catch {
            Log.network.error("feedback POST failed: \(String(describing: error), privacy: .public)")
            return .failure(ReportError(message: "The report couldn’t be sent. Please try again."))
        }
    }
}
```
(`Date()`/`UUID()` are used only inside `send`, never on the test path — the tests call `makeReport` with injected stamps, so they don't hit the `Date.now`-forbidden path.)

- [ ] **Step 4: Wire the file into project.pbxproj** (mirror `AgeGate.swift`, two fresh UUIDs; `plutil -lint` → OK).

- [ ] **Step 5: Run tests — expect PASS.**

- [ ] **Step 6: Commit** `git commit -m "Feedback: FeedbackReporter service + anonymous Keychain device id"`

---

### Task 2: `ReportContentSheet` UI

**Files:**
- Create: `hackertracker/Views/ReportContentSheet.swift`
- Modify: `hackertracker.xcodeproj/project.pbxproj`
- Test: none; build only.

**Interfaces:**
- Consumes: `FeedbackReporter.send(...)`, `ReportObjectType`, `Conference`, `InfoViewModel` (for `conference`), `ThemeManager`.
- Produces: `struct ReportContentSheet: View { init(objectType: ReportObjectType, objectId: Int) }` — presented via `.sheet`.

- [ ] **Step 1: Implement** — `hackertracker/Views/ReportContentSheet.swift`:

```swift
import SwiftUI

struct ReportContentSheet: View {
    let objectType: ReportObjectType
    let objectId: Int

    @Environment(InfoViewModel.self) private var viewModel
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.dismiss) private var dismiss

    @State private var message = ""
    @State private var sending = false
    @State private var errorText: String?
    @State private var sent = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextEditor(text: $message)
                        .frame(minHeight: 140)
                } header: {
                    Text("What’s wrong with this content?")
                } footer: {
                    Text("Please don’t include personal information. Your message and an anonymous app identifier are sent to the organizers.")
                }
            }
            .navigationTitle("Report an Issue")
            .themedNavTitle("Report an Issue", themeManager)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if sending { ProgressView() }
                    else {
                        Button("Send") { submit() }
                            .disabled(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .alert("Couldn’t Send", isPresented: .constant(errorText != nil)) {
                Button("Retry") { submit() }
                Button("Cancel", role: .cancel) { errorText = nil }
            } message: { Text(errorText ?? "") }
            .alert("Report Sent", isPresented: $sent) {
                Button("OK") { dismiss() }
            } message: { Text("Thanks — the organizers will take a look.") }
        }
    }

    private func submit() {
        guard let conference = viewModel.conference else {
            errorText = "No active conference."; return
        }
        errorText = nil
        sending = true
        Task {
            let result = await FeedbackReporter.send(
                message: message.trimmingCharacters(in: .whitespacesAndNewlines),
                conference: conference, objectType: objectType, objectId: objectId)
            sending = false
            switch result {
            case .success: sent = true
            case .failure(let e): errorText = e.message
            }
        }
    }
}
```

- [ ] **Step 2: Wire into project.pbxproj** (mirror `ListChrome.swift`, two fresh UUIDs; `plutil -lint` → OK).

- [ ] **Step 3: Build — expect BUILD SUCCEEDED.**

- [ ] **Step 4: Commit** `git commit -m "Feedback: ReportContentSheet UI"`

---

### Task 3: Toolbar entry on Content + Speaker detail

**Files:**
- Modify: `hackertracker/Views/ContentDetailView.swift`
- Modify: `hackertracker/Views/SpeakerDetailView.swift`
- Test: none; build only.

**Interfaces:**
- Consumes: `ReportContentSheet`, `ReportObjectType`.

- [ ] **Step 1: ContentDetailView** — add `@State private var showReport = false`. In the existing `.toolbar { … }` (around line 120), add a trailing item:

```swift
ToolbarItem(placement: .topBarTrailing) {
    Button {
        showReport = true
    } label: { Image(systemName: "exclamationmark.bubble") }
    .accessibilityLabel("Report an issue")
}
```

Attach the sheet on the same view:

```swift
.sheet(isPresented: $showReport) {
    ReportContentSheet(objectType: .content, objectId: contentId)
}
```
(Confirm the content id property name — `ContentDetailView(contentId:)` → use that stored id. Events route here, so `.content` is correct for both.)

- [ ] **Step 2: SpeakerDetailView** — same pattern, in its `.toolbar` (around line 85): a `showReport` state, a trailing "Report an issue" button, and `.sheet { ReportContentSheet(objectType: .person, objectId: id) }` (`id: Int` is the speaker id).

- [ ] **Step 3: Build — expect BUILD SUCCEEDED.**

- [ ] **Step 4: Commit** `git commit -m "Feedback: report entry on Content + Speaker detail"`

---

### Task 4: Toolbar entry on Org + Document detail

**Files:**
- Modify: `hackertracker/Views/OrgView.swift`
- Modify: `hackertracker/Views/DocumentView.swift`
- (Modify call sites that present a real Document with `DocumentView`, to pass a report context.)
- Test: none; build only.

**Interfaces:**
- Consumes: `ReportContentSheet`, `ReportObjectType`.
- Produces: `DocumentView` gains `var reportContext: (type: ReportObjectType, id: Int)? = nil` (default nil → no report item), so the generic viewer (privacy doc, org descriptions, emergency doc) shows nothing extra.

- [ ] **Step 1: OrgView** — add `@State private var showReport = false`. OrgView currently has no `.toolbar`; add one to its root view:

```swift
.toolbar {
    ToolbarItem(placement: .topBarTrailing) {
        Button { showReport = true } label: { Image(systemName: "exclamationmark.bubble") }
            .accessibilityLabel("Report an issue")
    }
}
.sheet(isPresented: $showReport) {
    ReportContentSheet(objectType: .org, objectId: 0)   // Organization has no Int id
}
```
(`org` is the `Organization` in scope; `object_id: 0` per spec.)

- [ ] **Step 2: DocumentView** — add the optional context parameter and a report item shown only when it's set:

```swift
var reportContext: (type: ReportObjectType, id: Int)? = nil
@State private var showReport = false
```
In DocumentView's `.toolbar` (add one if absent), conditionally:

```swift
if reportContext != nil {
    ToolbarItem(placement: .topBarTrailing) {
        Button { showReport = true } label: { Image(systemName: "exclamationmark.bubble") }
            .accessibilityLabel("Report an issue")
    }
}
```
And:

```swift
.sheet(isPresented: $showReport) {
    if let ctx = reportContext {
        ReportContentSheet(objectType: ctx.type, objectId: ctx.id)
    }
}
```

- [ ] **Step 3: Pass the context only for real documents** — grep `DocumentView(` across `Views/`. For the call site(s) that open an actual `Document` from the documents list (a `Document` with an `id: Int` in scope), add `reportContext: (.document, doc.id)`. Leave privacy-doc / org-description / emergency-doc call sites at the default `nil`.

- [ ] **Step 4: Build — expect BUILD SUCCEEDED.**

- [ ] **Step 5: Commit** `git commit -m "Feedback: report entry on Org + Document detail"`

---

## Self-Review

- Spec §"DeviceIdentifier" → Task 1 (`ReportDeviceIdentifier`) ✓; §"FeedbackReporter" → Task 1 ✓; §"ReportContentSheet" → Task 2 ✓; §"Wiring" (Content/Speaker/Org/Document) → Tasks 3–4 ✓; org `object_id: 0` → Task 4 Step 1 ✓; UTC timestamp + client string + snake_case keys → Task 1 (formatter + CodingKeys + test) ✓; anonymous-only privacy → Task 1 (Keychain UUID) ✓.
- Placeholders: none. The two "grep the call sites" steps (Document real-vs-generic) carry explicit criteria, not TODOs.
- Type consistency: `ReportObjectType`, `FeedbackReporter.makeReport(...)`/`.send(...)`, `ReportDeviceIdentifier.current()`, `ReportContentSheet(objectType:objectId:)`, `DocumentView.reportContext` used consistently across Tasks 1–4.
- **Execution notes:** Task 1 must confirm the `Conference` initializer to build the test stub (or decode a fixture). Tasks 3–4 must confirm each detail screen's exact toolbar/property (ContentDetailView content-id name; OrgView/DocumentView have no toolbar today — add one).
