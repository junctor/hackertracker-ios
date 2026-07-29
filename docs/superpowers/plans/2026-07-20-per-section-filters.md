# Per-Section Any/All Filters Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give each tagtype section in the Schedule + All Content filter its own Any/All mode, combined with AND across sections.

**Architecture:** A `SectionFilterModes` value (persisted as JSON `[tagTypeId: mode]` in AppStorage) drives a unified `filters()` predicate on `[Event]` and `[Content]`; the shared `EventFilters` sheet renders a per-section Any/All control shown only when a section has ≥2 chips selected.

**Tech Stack:** Swift 6, SwiftUI, `@Observable`/`@AppStorage`, XCTest.

## Global Constraints

- Deployment target stays iOS 17.0.
- Cross-section combination is **AND**; per-section is Any/All. Pseudo-toggles (Bookmarks/Custom/Has Notes) are each their own AND constraint (no Any/All).
- Per-section control appears only when that section has **≥2** chips selected. Default mode `.any`.
- Scope: Schedule (`EventsView`) + All Content (`ContentListView`) via the shared `EventFilters` sheet. Speakers/Merch (`filterMatchModeSpeakers`/`filterMatchModeMerch`) are **unchanged**.
- New source files need manual `project.pbxproj` wiring (not a synchronized group). Tests append to `hackertrackerTests/hackertrackerTests.swift`.
- Build: `xcodebuild -project hackertracker.xcodeproj -scheme hackertracker -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.2' build`; Test: same with `test`.

---

### Task 1: `SectionFilterModes` store

**Files:**
- Create: `hackertracker/Utils/SectionFilterModes.swift`
- Modify: `hackertracker/Utils/AppStorageKeys.swift` (add `sectionFilterModes` key)
- Modify: `hackertracker.xcodeproj/project.pbxproj` (wire the new file)
- Test: `hackertrackerTests/hackertrackerTests.swift`

**Interfaces:**
- Produces: `struct SectionFilterModes` with `init(json: String)`, `var jsonString: String`, `func mode(for tagTypeId: Int) -> FilterMatchMode` (default `.any`), `mutating func setMode(_:for:)`.
- Consumes: existing `FilterMatchMode` (`Utils/ModelExt.swift`).

- [ ] **Step 1: Failing tests** — append:

```swift
func testSectionModesDefaultsToAny() {
    let m = SectionFilterModes(json: "")
    XCTAssertEqual(m.mode(for: 5), .any)
}
func testSectionModesRoundTripsJSON() {
    var m = SectionFilterModes(json: "")
    m.setMode(.all, for: 5)
    let restored = SectionFilterModes(json: m.jsonString)
    XCTAssertEqual(restored.mode(for: 5), .all)
    XCTAssertEqual(restored.mode(for: 6), .any)
}
```

- [ ] **Step 2: Run — expect FAIL** (`cannot find 'SectionFilterModes'`).

- [ ] **Step 3: Implement** — `hackertracker/Utils/SectionFilterModes.swift`:

```swift
import Foundation

/// Per-tagtype-section Any/All modes for the Schedule + All Content filter.
/// Persisted as a JSON object [tagTypeId(String): "any"|"all"] in a single
/// AppStorage string. Sections with no stored entry default to `.any`.
struct SectionFilterModes: Equatable {
    private var modes: [Int: FilterMatchMode]

    init(json: String) {
        guard let data = json.data(using: .utf8),
              let raw = try? JSONDecoder().decode([String: String].self, from: data) else {
            modes = [:]; return
        }
        modes = raw.reduce(into: [:]) { acc, kv in
            if let id = Int(kv.key), let mode = FilterMatchMode(rawValue: kv.value) {
                acc[id] = mode
            }
        }
    }

    var jsonString: String {
        let raw = modes.reduce(into: [String: String]()) { $0[String($1.key)] = $1.value.rawValue }
        guard let data = try? JSONEncoder().encode(raw),
              let s = String(data: data, encoding: .utf8) else { return "" }
        return s
    }

    func mode(for tagTypeId: Int) -> FilterMatchMode { modes[tagTypeId] ?? .any }
    mutating func setMode(_ mode: FilterMatchMode, for tagTypeId: Int) { modes[tagTypeId] = mode }

    /// Convenience: the raw dictionary, for passing into the predicate.
    var asDictionary: [Int: FilterMatchMode] { modes }
}
```

- [ ] **Step 4: Add the AppStorage key** — in `AppStorageKeys.swift` add:

```swift
    static let sectionFilterModes = "sectionFilterModes.v1"
```

- [ ] **Step 5: Wire the file into project.pbxproj** — mirror an existing `Utils` file (e.g. `AgeGate.swift`): add a PBXBuildFile, a PBXFileReference, a Utils-group child entry, and a Sources build-phase entry, using two fresh 24-hex-char UUIDs (`openssl rand -hex 12 | tr a-z A-Z`). Verify: `plutil -lint hackertracker.xcodeproj/project.pbxproj` → OK.

- [ ] **Step 6: Run tests — expect PASS.**

- [ ] **Step 7: Commit** `git commit -m "Filters: SectionFilterModes store + AppStorage key"`

---

### Task 2: Unified per-section predicate (`ModelExt.swift`)

**Files:**
- Modify: `hackertracker/Utils/ModelExt.swift` (both `[Event]` and `[Content]` `filters(...)`)
- Test: `hackertrackerTests/hackertrackerTests.swift`

**Interfaces:**
- Consumes: `SectionFilterModes.asDictionary` (`[Int: FilterMatchMode]`), `FilterMatchMode`, `PseudoTagID`.
- Produces: `[Event].filters(typeIds:bookmarks:tagTypes:eventNoteIDs:contentNoteIDs:sectionModes:)` and `[Content].filters(typeIds:bookmarks:tagTypes:contentNoteIDs:sectionModes:)`, where `sectionModes: [Int: FilterMatchMode]`. A shared free function `ageAgnosticSectionMatch(tagIds:selectedByType:sectionModes:) -> Bool`.

- [ ] **Step 1: Failing tests** — append (using real `TagType`/`Tag` construction; check `Models/Tag.swift` for the initializer and adapt):

```swift
func testSectionAnyMatchesEitherTag() {
    // Section 100 has tags 1,2 selected in .any mode.
    let match = sectionFilterMatch(tagIds: [2, 9],
                                   selectedByType: [100: [1, 2]],
                                   sectionModes: [100: .any])
    XCTAssertTrue(match)   // has tag 2 → any passes
}
func testSectionAllRequiresBothTags() {
    XCTAssertFalse(sectionFilterMatch(tagIds: [1], selectedByType: [100: [1, 2]], sectionModes: [100: .all]))
    XCTAssertTrue(sectionFilterMatch(tagIds: [1, 2], selectedByType: [100: [1, 2]], sectionModes: [100: .all]))
}
func testTwoSectionsAreANDed() {
    // Type 100 {1} any, Organizer 200 {5} any → needs a 100-tag AND a 200-tag.
    let sel = [100: [1], 200: [5]]
    XCTAssertFalse(sectionFilterMatch(tagIds: [1], selectedByType: sel, sectionModes: [:]))       // missing 200
    XCTAssertTrue(sectionFilterMatch(tagIds: [1, 5], selectedByType: sel, sectionModes: [:]))       // both → default .any each
}
```

- [ ] **Step 2: Run — expect FAIL** (`cannot find 'sectionFilterMatch'`).

- [ ] **Step 3: Implement the shared matcher** — add to `ModelExt.swift` (top-level, file-private-free function so both overloads and the tests can call it; if tests need access use `internal`):

```swift
/// Core per-section filter decision. `selectedByType` maps tagTypeId ->
/// selected real tag ids in that section. For each active section, `.any`
/// requires the item to carry at least one of the section's tags; `.all`
/// requires all of them. Active sections are combined with AND. No sections
/// → true (caller handles the empty-selection short-circuit).
func sectionFilterMatch(tagIds: [Int],
                        selectedByType: [Int: [Int]],
                        sectionModes: [Int: FilterMatchMode]) -> Bool {
    let itemTags = Set(tagIds)
    for (typeId, selected) in selectedByType {
        let mode = sectionModes[typeId] ?? .any
        let ok: Bool
        switch mode {
        case .any: ok = selected.contains { itemTags.contains($0) }
        case .all: ok = selected.allSatisfy { itemTags.contains($0) }
        }
        if !ok { return false }   // AND across sections
    }
    return true
}
```

- [ ] **Step 4: Rewrite `[Event].filters(...)`** — replace its `mode: FilterMatchMode` parameter with `sectionModes: [Int: FilterMatchMode] = [:]`. Build `selectedByType` by grouping the real (non-pseudo) selected tag ids by their tagtype (reuse the existing `filterTypes` grouping loop). The predicate:

```swift
return filter { event in
    // Tag sections (AND across sections, per-section any/all).
    if !selectedByType.isEmpty,
       !sectionFilterMatch(tagIds: event.tagIds, selectedByType: selectedByType, sectionModes: sectionModes) {
        return false
    }
    // Pseudo constraints — each active one is its own AND.
    if useBookmarks, !bookmarks.contains(Int32(event.id)) { return false }
    if useCustom, event.customEventID == nil { return false }
    if useHasNotes, !(eventNoteIDs.contains(Int32(event.id)) || contentNoteIDs.contains(Int32(event.contentId))) { return false }
    return true
}
```
Keep the `typeIds.isEmpty → return self` short-circuit. `useBookmarks/useCustom/useHasNotes` are the existing `typeIds.contains(PseudoTagID.x)` checks.

- [ ] **Step 5: Rewrite `[Content].filters(...)`** — give it the same shape: parameters `typeIds:bookmarks:tagTypes:contentNoteIDs:sectionModes:` (Content has no per-event bookmark/custom; keep the existing bookmark pseudo via `bookmarks` set keyed on content id, and Has-Notes via `contentNoteIDs`). Group real tags into `selectedByType`, then:

```swift
return filter { content in
    if !selectedByType.isEmpty,
       !sectionFilterMatch(tagIds: content.tagIds, selectedByType: selectedByType, sectionModes: sectionModes) {
        return false
    }
    if typeIds.contains(PseudoTagID.bookmarks), !bookmarks.contains(Int32(content.id)) { return false }
    if typeIds.contains(PseudoTagID.hasNotes), !contentNoteIDs.contains(Int32(content.id)) { return false }
    return true
}
```
Remove the old `isFiltered(...)` helper if no longer referenced (grep first; delete only if unused).

- [ ] **Step 6: Run tests — expect PASS.**

- [ ] **Step 7: Commit** `git commit -m "Filters: unified per-section AND predicate for events + content"`

---

### Task 3: Per-section Any/All control in `EventFilters`

**Files:**
- Modify: `hackertracker/Views/FiltersView.swift`
- Test: none (UI); build only.

**Interfaces:**
- Consumes: `SectionFilterModes`, `AppStorageKeys.sectionFilterModes`, existing `Filters` env object, `MatchModePickerRow` (reuse its segmented styling or a small inline `Picker`).

- [ ] **Step 1: Bind a SectionFilterModes to AppStorage** — replace the `@AppStorage(AppStorageKeys.filterMatchMode) … filterMatchModeRaw` with:

```swift
    @AppStorage(AppStorageKeys.sectionFilterModes) private var sectionModesRaw: String = ""
```

Add a helper to read/mutate it:

```swift
    private func binding(forTagType id: Int) -> Binding<FilterMatchMode> {
        Binding(
            get: { SectionFilterModes(json: sectionModesRaw).mode(for: id) },
            set: { newValue in
                var m = SectionFilterModes(json: sectionModesRaw)
                m.setMode(newValue, for: id)
                sectionModesRaw = m.jsonString
            }
        )
    }
```

- [ ] **Step 2: Remove the global `MatchModePickerRow(raw: $filterMatchModeRaw)`** line at the top of the ScrollView (keep `FilterMatchCountLabel`).

- [ ] **Step 3: Add the per-section control to each tagtype header** — in the `ForEach(tagtypes...)` section `header:`, show an Any/All segmented control only when ≥2 chips of that tagtype are selected:

```swift
} header: {
    HStack {
        Text(tagtype.label)
            .frame(maxWidth: .infinity, alignment: .leading)
        let selectedInSection = tagtype.tags.filter { filters.filters.contains($0.id) }.count
        if selectedInSection >= 2 {
            Picker("", selection: binding(forTagType: tagtype.id)) {
                Text("Any").tag(FilterMatchMode.any)
                Text("All").tag(FilterMatchMode.all)
            }
            .pickerStyle(.segmented)
            .fixedSize()
        }
    }
}
```

- [ ] **Step 4: Build — expect BUILD SUCCEEDED.**

- [ ] **Step 5: Commit** `git commit -m "Filters: per-section Any/All control in the filter sheet"`

---

### Task 4: Wire consumers (`EventsView`, `ContentListView`)

**Files:**
- Modify: `hackertracker/Views/EventsView.swift`
- Modify: `hackertracker/Views/ContentListView.swift`
- Test: none; build only.

**Interfaces:**
- Consumes: `SectionFilterModes`, `AppStorageKeys.sectionFilterModes`, the Task-2 `filters(... sectionModes:)`.

- [ ] **Step 1: EventsView** — replace `@AppStorage(...filterMatchMode) filterMatchModeRaw` + the `filterMatchMode` computed var with:

```swift
    @AppStorage(AppStorageKeys.sectionFilterModes) private var sectionModesRaw: String = ""
    private var sectionModes: [Int: FilterMatchMode] { SectionFilterModes(json: sectionModesRaw).asDictionary }
```

Update every `.filters(... mode: filterMatchMode)` call to `.filters(... sectionModes: sectionModes)`. In `schedulePipelineKey`, replace `hasher.combine(filterMatchModeRaw)` with `hasher.combine(sectionModesRaw)`.

- [ ] **Step 2: ContentListView** — same replacement: `sectionModesRaw` + `sectionModes`, and pass `sectionModes:` into its `.filters(...)` / grouping predicate (where it currently uses `let mode = filterMatchMode`).

- [ ] **Step 3: Remove the now-unused `filterMatchMode` AppStorage key** — grep `AppStorageKeys.filterMatchMode` across the app; if only Speakers/Merch keys (`filterMatchModeSpeakers`/`Merch`) remain used and plain `filterMatchMode` has no readers, delete the `static let filterMatchMode` line from `AppStorageKeys.swift`. If any reader remains, leave it.

- [ ] **Step 4: Build — expect BUILD SUCCEEDED.**

- [ ] **Step 5: Full test run — expect the Task 1/2 tests still pass.**

- [ ] **Step 6: Commit** `git commit -m "Filters: drive Schedule + All Content from per-section modes"`

---

## Self-Review

- Spec §"Section-mode model" → Task 1 ✓; §"Predicate change" → Task 2 ✓; §"Filter sheet UI" → Task 3 ✓; §"Consumers" → Task 4 ✓.
- Pseudo-toggles as AND constraints → Task 2 Steps 4/5 ✓. Default `.any` → Task 1 `mode(for:)` ✓. ≥2-selected visibility → Task 3 Step 3 ✓. Speakers/Merch untouched (their own keys) ✓.
- No placeholders; the one "grep before deleting" (isFiltered / filterMatchMode key) is a conditional cleanup with explicit criteria, not a TODO.
- Type consistency: `sectionModes: [Int: FilterMatchMode]`, `SectionFilterModes(json:)`/`.asDictionary`/`.mode(for:)`/`.setMode(_:for:)`, `sectionFilterMatch(tagIds:selectedByType:sectionModes:)` used consistently across Tasks 1–4.
- **Execution note:** Task 2 must confirm `Tag`/`TagType` initializers before writing the test fixtures, and confirm the exact current `[Content].filters` call site in `ContentListView` (it uses an inline predicate, not necessarily the extension) — adapt the wiring to whichever it uses.
