# Age Verification Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Hide age-restricted Content and Organizations from users Apple confirms are under an item's `visible_age_min`, using the Declared Age Range API on iOS 26+.

**Architecture:** A single `AgeGate` service (in `Utils/AgeGate.swift`) owns the Declared Age Range query behind an injectable `AgeRangeProviding` protocol, caches a coarse bracket, and exposes `isVisible(minAge:)`. `InfoViewModel` holds the gate, keeps raw decoded arrays private, and publishes age-filtered `content`/`events`/`orgs` (+ their id maps) so every screen is covered at one chokepoint. Fail-open: hide only on a positive under-age signal.

**Tech Stack:** Swift 6, SwiftUI, `@Observable`, Firebase Firestore (Codable), `DeclaredAgeRange` (iOS 26+), XCTest.

## Global Constraints

- Deployment target stays **iOS 17.0**. All Declared Age Range code is gated by `if #available(iOS 26, *)`; on older OS the feature is a no-op and everything shows.
- Requested age gates are exactly **[13, 16, 18]** (`AgeGateConfig.requestedGates`).
- Absent `visible_age_min` → `AgeGateConfig.defaultMinAge`, which is **`nil` (no minimum)** today and must be changeable in one place.
- **Fail open:** hide an item only when we have a confident under-age signal (`upperBound < minAge`). Declined / error / indeterminate / in-flight / iOS <26 all resolve to visible.
- Only Content and Organizations are gated. Speakers are not.
- Firestore documents without `visible_age_min` must continue to decode unchanged.
- Project is NOT a synchronized folder group (`PBXFileSystemSynchronizedRootGroup` count = 0): every new `.swift` source file requires manual `project.pbxproj` wiring (PBXBuildFile + PBXFileReference + Utils group child + Sources build phase). New tests are appended to the existing `hackertrackerTests/hackertrackerTests.swift` (no pbxproj change).
- Build/verify command:
  `xcodebuild -project hackertracker.xcodeproj -scheme hackertracker -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.2' build`
- Test command:
  `xcodebuild -project hackertracker.xcodeproj -scheme hackertracker -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.2' test`

---

### Task 1: `visible_age_min` on the data models

**Files:**
- Modify: `hackertracker/Models/Content.swift` (struct fields + CodingKeys)
- Modify: `hackertracker/Models/Organization.swift` (struct fields + CodingKeys)
- Modify: `hackertracker/Models/Event.swift` (add non-CodingKey property)
- Modify: `hackertracker/ViewModels/InfoViewModel.swift` (propagate into synthesized events, in `fetchContent`)
- Test: `hackertrackerTests/hackertrackerTests.swift` (append decode tests)

**Interfaces:**
- Produces: `Content.visibleAgeMin: Int?`, `Organization.visibleAgeMin: Int?`, `Event.visibleAgeMin: Int?`.

- [ ] **Step 1: Write failing decode tests** — append to `hackertrackerTests/hackertrackerTests.swift`:

```swift
func testContentDecodesVisibleAgeMin() throws {
    let json = """
    {"id": 1, "description": "d", "links": [], "media": [], "people": [],
     "sessions": [], "tag_ids": [], "title": "t", "visible_age_min": 18}
    """.data(using: .utf8)!
    let content = try JSONDecoder().decode(Content.self, from: json)
    XCTAssertEqual(content.visibleAgeMin, 18)
}

func testContentDefaultsVisibleAgeMinToNilWhenAbsent() throws {
    let json = """
    {"id": 2, "description": "d", "links": [], "media": [], "people": [],
     "sessions": [], "tag_ids": [], "title": "t"}
    """.data(using: .utf8)!
    let content = try JSONDecoder().decode(Content.self, from: json)
    XCTAssertNil(content.visibleAgeMin)
}

func testOrganizationDecodesVisibleAgeMin() throws {
    let json = """
    {"name": "n", "description": "d", "links": [], "media": [],
     "tag_ids": [], "visible_age_min": 21}
    """.data(using: .utf8)!
    let org = try JSONDecoder().decode(Organization.self, from: json)
    XCTAssertEqual(org.visibleAgeMin, 21)
}
```

- [ ] **Step 2: Run tests, verify they fail**

Run the test command (filter if desired: `-only-testing:hackertrackerTests/hackertrackerTests/testContentDecodesVisibleAgeMin`).
Expected: FAIL — `value of type 'Content' has no member 'visibleAgeMin'` (compile error).

- [ ] **Step 3: Add the field to Content** — in `hackertracker/Models/Content.swift`, add after `var feedbackFormId: Int?` (line ~26):

```swift
    /// Minimum age required to see this content. Absent → no minimum
    /// (see AgeGateConfig.defaultMinAge). Enforced only on iOS 26+.
    var visibleAgeMin: Int?
```

and add to the `CodingKeys` enum (after `case feedbackFormId = "feedback_form_id"`):

```swift
        case visibleAgeMin = "visible_age_min"
```

- [ ] **Step 4: Add the field to Organization** — in `hackertracker/Models/Organization.swift`, add after `var tag_id_as_organizer: Int?` (line ~19):

```swift
    /// Minimum age required to see this organization. Absent → no minimum.
    var visibleAgeMin: Int?
```

and to its `CodingKeys` (after `case tag_id_as_organizer`):

```swift
        case visibleAgeMin = "visible_age_min"
```

- [ ] **Step 5: Add the field to Event** — in `hackertracker/Models/Event.swift`, add after `var customColorHex: String? = nil` (before the `CodingKeys` enum). Do NOT add it to `CodingKeys` — events are synthesized in code, not decoded from Firestore, matching the existing `customEventID`/`customColorHex` pattern:

```swift
    /// Minimum age required to see this event, copied from the parent
    /// Content by the synthesizer. NOT in CodingKeys (events are built in
    /// code); nil = no minimum.
    var visibleAgeMin: Int? = nil
```

- [ ] **Step 6: Propagate into synthesized events** — in `hackertracker/ViewModels/InfoViewModel.swift`, `fetchContent`, find the `Event(` initializer inside the `Task.detached` decode loop and add `visibleAgeMin: c.visibleAgeMin` to the argument list:

```swift
    let e = Event(id: s.id, contentId: c.id, description: c.description,
                  beginTimestamp: s.beginTimestamp, endTimestamp: s.endTimestamp,
                  title: c.title, locationId: s.locationId, people: c.people,
                  tagIds: c.tagIds, relatedIds: c.relatedIds,
                  visibleAgeMin: c.visibleAgeMin)
```

- [ ] **Step 7: Run tests, verify they pass** — run the test command. Expected: the three new tests PASS.

- [ ] **Step 8: Commit**

```bash
git add hackertracker/Models/Content.swift hackertracker/Models/Organization.swift hackertracker/Models/Event.swift hackertracker/ViewModels/InfoViewModel.swift hackertrackerTests/hackertrackerTests.swift
git commit -m "Age gate: add visible_age_min to Content/Organization/Event"
```

---

### Task 2: `AgeGate` service + visibility logic (TDD core)

**Files:**
- Create: `hackertracker/Utils/AgeGate.swift`
- Modify: `hackertracker.xcodeproj/project.pbxproj` (wire the new file)
- Test: `hackertrackerTests/hackertrackerTests.swift` (append)

**Interfaces:**
- Produces:
  - `enum AgeGateConfig { static let defaultMinAge: Int?; static let requestedGates: [Int] }`
  - `struct AgeRangeResult { let lowerBound: Int?; let upperBound: Int? }`
  - `protocol AgeRangeProviding { func requestRange(gates: [Int], forcePrompt: Bool) async -> AgeRangeResult }`
  - `struct NoopAgeRangeProvider: AgeRangeProviding` (returns `.init(lowerBound: nil, upperBound: nil)`)
  - `@Observable @MainActor final class AgeGate` with `init(provider:)`, `private(set) var lowerBound: Int?`, `private(set) var upperBound: Int?`, `func refresh(forcePrompt: Bool) async`, `func isVisible(minAge: Int?) -> Bool`.

- [ ] **Step 1: Write the failing tests** — append to `hackertrackerTests/hackertrackerTests.swift`:

```swift
@MainActor
final class AgeGateTests: XCTestCase {
    /// Feeds a fixed range so the decision logic can be tested without the OS.
    struct FakeProvider: AgeRangeProviding {
        let result: AgeRangeResult
        func requestRange(gates: [Int], forcePrompt: Bool) async -> AgeRangeResult { result }
    }

    private func gate(lower: Int?, upper: Int?) async -> AgeGate {
        let g = AgeGate(provider: FakeProvider(result: .init(lowerBound: lower, upperBound: upper)))
        await g.refresh(forcePrompt: false)
        return g
    }

    func testNilMinIsAlwaysVisible() async {
        let g = await gate(lower: 13, upper: 15)   // confirmed under 18
        XCTAssertTrue(g.isVisible(minAge: nil))     // no minimum → visible
    }

    func testConfirmedUnderIsHidden() async {
        let g = await gate(lower: 13, upper: 15)
        XCTAssertFalse(g.isVisible(minAge: 18))     // max age 15 < 18 → hidden
    }

    func testAtOrAboveMinIsVisible() async {
        let g = await gate(lower: 18, upper: nil)   // 18+
        XCTAssertTrue(g.isVisible(minAge: 18))
    }

    func testStraddleFailsOpen() async {
        let g = await gate(lower: 16, upper: 17)
        XCTAssertTrue(g.isVisible(minAge: 16))      // 17 >= 16 → visible
        XCTAssertFalse(g.isVisible(minAge: 18))     // 17 < 18 → hidden
    }

    func testUnknownRangeFailsOpen() async {
        let g = await gate(lower: nil, upper: nil)  // declined/error/pre-26
        XCTAssertTrue(g.isVisible(minAge: 18))      // no signal → visible
    }
}
```

- [ ] **Step 2: Run tests, verify they fail**

Run the test command. Expected: FAIL — `cannot find 'AgeGate' in scope` (compile error).

- [ ] **Step 3: Create the service** — write `hackertracker/Utils/AgeGate.swift`:

```swift
//
//  AgeGate.swift
//  hackertracker
//
//  Age-restriction gate backed by Apple's Declared Age Range API (iOS 26+).
//  On iOS < 26 there is no provider, so nothing is ever hidden.
//

import Foundation
import SwiftUI

enum AgeGateConfig {
    /// Applied when an item has no explicit visible_age_min.
    /// nil = no minimum. Change here to flip the default policy app-wide.
    static let defaultMinAge: Int? = nil
    /// Age gates requested from the Declared Age Range API.
    static let requestedGates: [Int] = [13, 16, 18]
}

/// Coarse age bracket. nil bounds = unknown (declined / error / iOS < 26).
struct AgeRangeResult {
    let lowerBound: Int?
    let upperBound: Int?
    static let unknown = AgeRangeResult(lowerBound: nil, upperBound: nil)
}

/// Injectable source of the declared age range. The real iOS-26 adapter is
/// added in Task 3; tests and iOS < 26 use NoopAgeRangeProvider.
protocol AgeRangeProviding: Sendable {
    func requestRange(gates: [Int], forcePrompt: Bool) async -> AgeRangeResult
}

struct NoopAgeRangeProvider: AgeRangeProviding {
    func requestRange(gates: [Int], forcePrompt: Bool) async -> AgeRangeResult { .unknown }
}

@Observable
@MainActor
final class AgeGate {
    private(set) var lowerBound: Int?
    private(set) var upperBound: Int?
    @ObservationIgnored private let provider: AgeRangeProviding

    init(provider: AgeRangeProviding = NoopAgeRangeProvider()) {
        self.provider = provider
        // Restore the cached bracket so filtering applies before refresh().
        let d = UserDefaults.standard
        self.lowerBound = d.object(forKey: Self.lowerKey) as? Int
        self.upperBound = d.object(forKey: Self.upperKey) as? Int
    }

    private static let lowerKey = "ageGate.lowerBound.v1"
    private static let upperKey = "ageGate.upperBound.v1"

    func refresh(forcePrompt: Bool = false) async {
        let result = await provider.requestRange(gates: AgeGateConfig.requestedGates,
                                                  forcePrompt: forcePrompt)
        lowerBound = result.lowerBound
        upperBound = result.upperBound
        let d = UserDefaults.standard
        d.set(result.lowerBound, forKey: Self.lowerKey)
        d.set(result.upperBound, forKey: Self.upperKey)
    }

    /// Fail-open decision: hide ONLY when the user's maximum possible age is
    /// below the item's minimum. Everything else is visible.
    func isVisible(minAge rawMin: Int?) -> Bool {
        let minAge = rawMin ?? AgeGateConfig.defaultMinAge
        guard let minAge else { return true }        // no minimum
        guard let upper = upperBound else { return true }  // no signal → fail open
        return upper >= minAge
    }
}
```

- [ ] **Step 4: Wire the file into the project** — edit `hackertracker.xcodeproj/project.pbxproj`. Mirror the existing `Theme.swift` entries (search for `Theme.swift` to copy the exact patterns), adding four entries with two fresh 24-hex-char UUIDs (call them `<BUILDUUID>` and `<FILEUUID>`, generate with `openssl rand -hex 12 | tr a-z A-Z`):
  1. PBXBuildFile section: `<BUILDUUID> /* AgeGate.swift in Sources */ = {isa = PBXBuildFile; fileRef = <FILEUUID> /* AgeGate.swift */; };`
  2. PBXFileReference section: `<FILEUUID> /* AgeGate.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = AgeGate.swift; sourceTree = "<group>"; };`
  3. The Utils group's `children = ( … )` list: `<FILEUUID> /* AgeGate.swift */,`
  4. The app target's Sources `PBXSourcesBuildPhase` `files = ( … )` list: `<BUILDUUID> /* AgeGate.swift in Sources */,`

  Verify: `plutil -lint hackertracker.xcodeproj/project.pbxproj` → `OK`.

- [ ] **Step 5: Run tests, verify they pass** — run the test command. Expected: all five `AgeGateTests` PASS.

- [ ] **Step 6: Commit**

```bash
git add hackertracker/Utils/AgeGate.swift hackertracker.xcodeproj/project.pbxproj hackertrackerTests/hackertrackerTests.swift
git commit -m "Age gate: AgeGate service + visibility logic (TDD)"
```

---

### Task 3: iOS 26 Declared Age Range provider

**Files:**
- Modify: `hackertracker/Utils/AgeGate.swift` (add the real provider)

**Interfaces:**
- Consumes: `AgeRangeProviding`, `AgeRangeResult`, `AgeGateConfig.requestedGates`.
- Produces: `DeclaredAgeRangeProvider: AgeRangeProviding` (real API adapter), and a factory `AgeGate.makeDefault()` that picks the real provider on iOS 26+ and `NoopAgeRangeProvider` otherwise.

> **API verification (do this first):** The exact `DeclaredAgeRange` symbol names — the service/request type, the request method signature, and the response cases — are from the iOS 26 API. Confirm them against current Apple documentation (search "Declared Age Range API" / the `DeclaredAgeRange` framework) before writing this adapter. The code below is the *shape*; adjust symbol names to match the shipped API. Nothing else in the feature depends on these names — only this adapter does.

- [ ] **Step 1: Add the real provider + factory** — append to `hackertracker/Utils/AgeGate.swift`:

```swift
import DeclaredAgeRange   // iOS 26+; guarded at the call site

/// Real adapter over Apple's Declared Age Range API. Maps the response to
/// AgeRangeResult; any decline/error/indeterminate → .unknown (fail open).
@available(iOS 26, *)
struct DeclaredAgeRangeProvider: AgeRangeProviding {
    func requestRange(gates: [Int], forcePrompt: Bool) async -> AgeRangeResult {
        do {
            // NOTE: confirm the exact API surface against Apple docs.
            let service = AgeRangeService()
            let response = try await service.requestAgeRange(ageGates: gates)
            switch response {
            case .sharing(let range):
                return AgeRangeResult(lowerBound: range.lowerBound,
                                      upperBound: range.upperBound)
            default:
                return .unknown   // declined / not shared → fail open
            }
        } catch {
            Log.app.error("age range request failed: \(String(describing: error), privacy: .public)")
            return .unknown
        }
    }
}

extension AgeGate {
    /// Picks the real provider on iOS 26+, no-op otherwise.
    static func makeDefault() -> AgeGate {
        if #available(iOS 26, *) {
            return AgeGate(provider: DeclaredAgeRangeProvider())
        } else {
            return AgeGate(provider: NoopAgeRangeProvider())
        }
    }
}
```

- [ ] **Step 2: Build**

Run the build command. Expected: **BUILD SUCCEEDED**. (If the SDK in use predates iOS 26 and `import DeclaredAgeRange` fails to resolve, wrap the import and provider in `#if canImport(DeclaredAgeRange)` and have `makeDefault()` fall back to `NoopAgeRangeProvider` — the app still builds and the feature is inert until built against the iOS 26 SDK.)

- [ ] **Step 3: Commit**

```bash
git add hackertracker/Utils/AgeGate.swift
git commit -m "Age gate: iOS 26 DeclaredAgeRange provider + factory"
```

---

### Task 4: Centralized filtering in `InfoViewModel`

**Files:**
- Modify: `hackertracker/ViewModels/InfoViewModel.swift`
- Test: `hackertrackerTests/hackertrackerTests.swift` (append)

**Interfaces:**
- Consumes: `AgeGate`, `AgeGate.makeDefault()`, `AgeGate.isVisible(minAge:)`.
- Produces on `InfoViewModel`:
  - `let ageGate: AgeGate` (public, so views/Settings can read status + trigger refresh)
  - `func refreshAgeGate(forcePrompt: Bool) async` — calls `ageGate.refresh` then re-applies the filter
  - Behavior: `content`, `events`, `orgs` (and `contentById`/`eventsById`/`orgsById`) reflect the age filter.

**Approach:** keep the public stored arrays (with their existing index-building `didSet`) but feed them from private raw arrays through one filter method. This preserves the O(1) id maps used on hot paths and changes only the assignment sites in `fetchContent`/`fetchOrgs`.

- [ ] **Step 1: Write the failing test** — append to `hackertrackerTests/hackertrackerTests.swift`:

```swift
@MainActor
func testInfoViewModelHidesUnderageContent() async {
    let vm = InfoViewModel(
        ageGate: AgeGate(provider: AgeGateTests.FakeProvider(
            result: .init(lowerBound: 13, upperBound: 15)))   // confirmed under 18
    )
    await vm.ageGate.refresh()
    vm._setDecodedContentForTesting([
        Content.stub(id: 1, visibleAgeMin: nil),
        Content.stub(id: 2, visibleAgeMin: 18)
    ])
    XCTAssertEqual(vm.content.map(\.id), [1])   // id 2 (18+) hidden from a 13–15 user
}
```

(Also add a `Content.stub(...)` test helper and `InfoViewModel._setDecodedContentForTesting(_:)` + a test-only `init(ageGate:)` — see Steps 3–4. These `_`-prefixed test seams are acceptable because InfoViewModel is otherwise Firestore-driven and not constructible in a test without them.)

- [ ] **Step 2: Run test, verify it fails** — run the test command. Expected: FAIL — `InfoViewModel` has no `ageGate` / `_setDecodedContentForTesting` (compile error).

- [ ] **Step 3: Add the gate + private raw arrays + filter** — in `hackertracker/ViewModels/InfoViewModel.swift`:

Add a stored gate near the top of the class:

```swift
    let ageGate: AgeGate
```

Add an initializer (the class currently relies on the implicit one; add an explicit one that defaults to the real gate, plus the injection point for tests):

```swift
    init(ageGate: AgeGate = .makeDefault()) {
        self.ageGate = ageGate
    }
```

Add private raw storage and the filter method:

```swift
    @ObservationIgnored private var rawContent: [Content] = []
    @ObservationIgnored private var rawEvents: [Event] = []
    @ObservationIgnored private var rawOrgs: [Organization] = []

    /// Re-derive the public (age-filtered) collections from the raw decoded
    /// arrays. Called after each decode and after the age bracket changes.
    func applyAgeFilter() {
        content = rawContent.filter { ageGate.isVisible(minAge: $0.visibleAgeMin) }
        events  = rawEvents.filter  { ageGate.isVisible(minAge: $0.visibleAgeMin) }
        orgs    = rawOrgs.filter    { ageGate.isVisible(minAge: $0.visibleAgeMin) }
    }

    /// Up-front + Settings entry point.
    func refreshAgeGate(forcePrompt: Bool = false) async {
        await ageGate.refresh(forcePrompt: forcePrompt)
        applyAgeFilter()
    }

    // Test seams (used only by the unit tests).
    func _setDecodedContentForTesting(_ c: [Content]) { rawContent = c; applyAgeFilter() }
```

- [ ] **Step 4: Route decode assignments through the raw arrays** — in `fetchContent`'s `MainActor.run` assignment, change `self.content = decodedContent` / `self.events = rebuiltEvents` to:

```swift
    self.rawContent = decodedContent
    self.rawEvents = rebuiltEvents
    self.applyAgeFilter()   // sets self.content / self.events (filtered)
```

In `fetchOrgs`'s assignment, change `self.orgs = decodedOrgs` to:

```swift
    self.rawOrgs = decodedOrgs
    self.applyAgeFilter()
```

(Leave the existing `didSet` index-builders on `content`/`events`/`orgs` untouched — they now rebuild the maps from the filtered arrays, which is what we want.)

Add the `Content.stub` test helper at the bottom of the test file:

```swift
extension Content {
    static func stub(id: Int, visibleAgeMin: Int?) -> Content {
        Content(id: id, conferenceName: nil, description: "", links: [], logo: nil,
                media: [], people: [], sessions: [], tagIds: [], relatedIds: nil,
                title: "stub", feedbackDisableTimestamp: nil, feedbackEnableTimestamp: nil,
                feedbackFormId: nil, visibleAgeMin: visibleAgeMin)
    }
}
```

(If `Content`'s member-wise initializer differs, match its actual stored properties — check `Content.swift`.)

- [ ] **Step 5: Run test, verify it passes** — run the test command. Expected: `testInfoViewModelHidesUnderageContent` PASSES.

- [ ] **Step 6: Build the app** — run the build command. Expected: **BUILD SUCCEEDED** (confirms the `fetchContent`/`fetchOrgs` edits compile in context).

- [ ] **Step 7: Commit**

```bash
git add hackertracker/ViewModels/InfoViewModel.swift hackertrackerTests/hackertrackerTests.swift
git commit -m "Age gate: centralized age filtering in InfoViewModel"
```

---

### Task 5: Up-front trigger on launch

**Files:**
- Modify: `hackertracker/Views/ContentView.swift`

**Interfaces:**
- Consumes: `InfoViewModel.refreshAgeGate(forcePrompt:)`.

- [ ] **Step 1: Call the gate on launch** — in `hackertracker/Views/ContentView.swift`, find the `.task { … }` on the populated `TabView` branch (the one that sets `launchScreen`/`viewModel.showNews`). Add at the end of that closure:

```swift
                // Age gate: query the declared age range up front so
                // restricted content is filtered before the user browses.
                await viewModel.refreshAgeGate()
```

- [ ] **Step 2: Build**

Run the build command. Expected: **BUILD SUCCEEDED**.

- [ ] **Step 3: Manual smoke (documented, not automated)** — on an iPad/ierPhone iOS 26 sim: launch → the system age sheet may appear once; with a Firestore item carrying `visible_age_min: 18` and a declared under-18 range, that item is absent from Schedule/All Content/Orgs/Search. On an iOS 17–25 sim: everything shows, no sheet. (No unit test — this is UI/OS behavior.)

- [ ] **Step 4: Commit**

```bash
git add hackertracker/Views/ContentView.swift
git commit -m "Age gate: query declared age range up front on launch"
```

---

### Task 6: Settings — "Age Verification" row

**Files:**
- Modify: `hackertracker/Views/SettingsView.swift`

**Interfaces:**
- Consumes: `InfoViewModel.ageGate` (`lowerBound`/`upperBound`), `InfoViewModel.refreshAgeGate(forcePrompt:)`.

- [ ] **Step 1: Add the settings section** — in `hackertracker/Views/SettingsView.swift`, add a new view struct following the existing `AISummarySettingsView` pattern (env `@Environment(InfoViewModel.self) private var viewModel`, `@Environment(ThemeManager.self) private var themeManager`, `.settingsCard(themeManager)`):

```swift
struct AgeVerificationSettingsView: View {
    @Environment(InfoViewModel.self) private var viewModel
    @Environment(ThemeManager.self) private var themeManager
    @State private var verifying = false

    private var statusText: String {
        if #available(iOS 26, *) {
            if let lower = viewModel.ageGate.lowerBound {
                return "Verified: \(lower)+"
            }
            return "Not verified"
        }
        return "Unavailable on this iOS"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Age Verification")
                .font(themeManager.headingFont)
            Text(statusText)
                .font(themeManager.captionFont)
                .foregroundStyle(.secondary)
            if #available(iOS 26, *) {
                Button {
                    verifying = true
                    Task {
                        await viewModel.refreshAgeGate(forcePrompt: true)
                        verifying = false
                    }
                } label: {
                    Text(verifying ? "Verifying…" : "Verify Age")
                }
                .disabled(verifying)
                Text("Age-restricted content is shown based on your device's declared age range.")
                    .font(themeManager.captionFont)
                    .foregroundStyle(.secondary)
            }
        }
        .settingsCard(themeManager)
    }
}
```

- [ ] **Step 2: Render it in the settings list** — in `SettingsView.body`, add `AgeVerificationSettingsView()` to both the iPad two-column layout (a `VStack(spacing: 0) { AgeVerificationSettingsView() }` in one of the columns) and the iPhone single-column list (alongside `AISummarySettingsView()`).

- [ ] **Step 3: Build**

Run the build command. Expected: **BUILD SUCCEEDED**.

- [ ] **Step 4: Commit**

```bash
git add hackertracker/Views/SettingsView.swift
git commit -m "Age gate: Settings age-verification status + re-verify"
```

---

### Task 7: Final verification

**Files:** none (verification only)

- [ ] **Step 1: Full build + test**

Run the build command, then the test command. Expected: **BUILD SUCCEEDED** and all tests (including the new decode / AgeGate / InfoViewModel tests) PASS.

- [ ] **Step 2: swiftlint** — run `swiftlint` and confirm no NEW violations attributable to the added files.

- [ ] **Step 3: Confirm backward compatibility** — grep confirms `visible_age_min` decodes optionally and no deployment-target change was introduced:

```bash
grep -n "iOS 26" hackertracker/Utils/AgeGate.swift
grep -n "IPHONEOS_DEPLOYMENT_TARGET" hackertracker.xcodeproj/project.pbxproj | sort -u
```

Expected: availability guards present in AgeGate; deployment target still `17.0`.

---

## Self-Review

**Spec coverage:**
- visible_age_min on Content/Org/Event → Task 1 ✓
- AgeGate service, gates [13,16,18], caching, fail-open isVisible → Task 2 ✓
- iOS 26 provider behind availability + protocol isolation → Task 3 ✓
- Centralized InfoViewModel filtering (Approach A) covering all surfaces → Task 4 ✓
- Up-front trigger → Task 5 ✓
- Settings status + re-verify → Task 6 ✓
- Default configurable (`AgeGateConfig.defaultMinAge`) → Task 2 ✓
- Pre-26 no-op / iOS 17 floor unchanged → Tasks 2/3/7 ✓
- Unit tests for isVisible matrix → Task 2 ✓
- Privacy: only coarse bracket cached → Task 2 (UserDefaults ints) ✓

**Placeholder scan:** No TBD/TODO. The one deliberate uncertainty (exact DeclaredAgeRange symbols) is isolated to Task 3 with an explicit "verify against docs first" instruction and a `#if canImport` fallback — not a silent gap.

**Type consistency:** `AgeRangeResult(lowerBound:upperBound:)`, `AgeRangeProviding.requestRange(gates:forcePrompt:)`, `AgeGate.isVisible(minAge:)`, `AgeGate.refresh(forcePrompt:)`, `InfoViewModel.refreshAgeGate(forcePrompt:)`, `applyAgeFilter()` — names match across Tasks 2/3/4/5/6. `AgeGate.makeDefault()` (Task 3) is the default arg in `InfoViewModel.init` (Task 4). `FakeProvider` is defined in `AgeGateTests` (Task 2) and reused in Task 4's test via `AgeGateTests.FakeProvider`.

**Known risk to watch during execution:** Task 4 assumes `fetchContent` assigns `self.content`/`self.events` in a `MainActor.run` block and `fetchOrgs` assigns `self.orgs` — confirm the exact current assignment lines before editing (they were touched by the Phase 3 off-main-decode work). The edit is "assign raw + call applyAgeFilter()" regardless of the surrounding structure.
