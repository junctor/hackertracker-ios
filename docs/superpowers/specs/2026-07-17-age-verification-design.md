# Age Verification — Design Spec

**Date:** 2026-07-17
**Status:** Approved for planning
**Feature branch:** `feature/age-verification`

## Summary

Age-gate conference content and organizations using Apple's **Declared Age Range API**
(`DeclaredAgeRange`, iOS 26+). A new optional `visible_age_min` field on Content and
Organization documents declares the minimum age required to see an item. On iOS 26+ the
app queries the user's declared age range up front and hides items the user is confirmed
to be too young for. On iOS 17–25 the API does not exist, so the feature is a no-op and
all content shows normally.

This is a privacy-preserving design: the Declared Age Range API returns a coarse age
*bracket*, never a birthdate, and for child/teen accounts it is parent-controlled via
Family Sharing. It aligns with HackerTracker's existing posture (no tracking, no IDFA).

## Requirements & decisions

| # | Decision | Choice |
|---|----------|--------|
| 1 | Platform scope | **iOS 26+ only.** No self-attestation fallback. |
| 2 | Pre-iOS-26 behavior | Feature is a no-op; **all content shown ungated**. |
| 3 | iOS 26 trigger + visibility | **Query up front; hide until cleared.** Settings offers re-verify. |
| 4 | Age thresholds (gates requested) | **Apple brackets: [13, 16, 18].** `visible_age_min` values are drawn from this set. |
| 5 | Decline / error / indeterminate | **Fail open (show).** |
| 6 | Absent `visible_age_min` | Use `AgeGateConfig.defaultMinAge` — **`nil` (no minimum)** today, changeable in one place. |
| 7 | Architecture | **Approach A** — isolated `AgeGate` service + centralized filtering in `InfoViewModel`. |

### Reconciling "hide until cleared" with "fail open"

Taken together these mean: **an item is hidden only when the API positively confirms the
user is below that item's minimum.** Every other state — declined, errored, indeterminate,
query in flight, or iOS < 26 — resolves to *visible*. The gate's job is narrow and
defensible: when Apple tells us a user is under the threshold, remove restricted items for
that user; everyone else sees everything.

## Scope

**In scope**
- `visible_age_min` decoding on Content and Organization; propagation to synthesized Events.
- An `AgeGate` service wrapping the Declared Age Range API (iOS 26+), with caching and an
  injectable range provider.
- Centralized age filtering in `InfoViewModel` so all consuming surfaces are covered.
- Up-front query on launch and a Settings "Verify Age" action.
- Unit tests for the visibility decision logic.

**Out of scope / non-goals**
- Any pre-iOS-26 verification (self-attestation, birthdate entry).
- Gating of Speakers (requirement covers Content + Organizations only). A speaker's linked
  events are still individually gated through the Event filter; the speaker row itself is not.
- Server/authoring changes for `visible_age_min` (handled on the backend).
- Persisting anything sensitive: only a coarse age bracket is cached, never a birthdate.

## Architecture

### 1. Data model

- `Content.visibleAgeMin: Int?` — CodingKey `visible_age_min`. Optional; absent → `nil`.
- `Organization.visibleAgeMin: Int?` — CodingKey `visible_age_min`. Optional; absent → `nil`.
- `Event.visibleAgeMin: Int?` — new stored property, populated from the parent `Content`
  where `InfoViewModel.fetchContent` builds events
  (`Event(… visibleAgeMin: c.visibleAgeMin)`).

Decoding must remain backward-compatible: existing documents without the field decode with
`nil` and are unaffected.

### 2. `AgeGate` service

The single place that references `DeclaredAgeRange`. Sketch (names indicative; see
"API verification" below):

```
enum AgeGateConfig {
    /// Applied when an item has no explicit visible_age_min. nil = no minimum.
    /// Change here to flip the default policy app-wide.
    static let defaultMinAge: Int? = nil
    /// Age gates requested from the Declared Age Range API.
    static let requestedGates: [Int] = [13, 16, 18]
}

/// Injectable so the Apple call is faked in tests and no-op'd on iOS < 26.
protocol AgeRangeProviding {
    func requestRange(gates: [Int], forcePrompt: Bool) async -> AgeRangeResult
}
struct AgeRangeResult { let lowerBound: Int?; let upperBound: Int? }  // nil/nil = unknown

@Observable @MainActor final class AgeGate {
    private(set) var lowerBound: Int?   // cached to @AppStorage
    private(set) var upperBound: Int?   // cached to @AppStorage
    private let provider: AgeRangeProviding

    func refresh(forcePrompt: Bool = false) async { … }   // updates + caches bounds

    /// Core decision. Hide ONLY when confidently under the minimum; else show.
    func isVisible(minAge rawMin: Int?) -> Bool {
        let minAge = rawMin ?? AgeGateConfig.defaultMinAge
        guard let minAge else { return true }               // no minimum
        guard let upper = upperBound else { return true }   // no confident signal → fail open
        return upper >= minAge                              // hide only if confirmed under
    }
}
```

- **Real provider** (`if #available(iOS 26, *)`) calls the Declared Age Range API with
  `AgeGateConfig.requestedGates` and maps the response to `AgeRangeResult`; declined / error
  map to `nil/nil`.
- **No-op provider** (iOS < 26, and the default in previews/tests) returns `nil/nil`.
- **Caching:** `lowerBound`/`upperBound` persist in `@AppStorage` (a coarse bracket, no
  birthdate) so filtering applies instantly on next launch before the async `refresh()`
  resolves.

### 3. Filtering in `InfoViewModel` (Approach A)

- `InfoViewModel` holds the `AgeGate`. The raw decoded arrays stay private; the
  consumer-facing `content`, `events`, `orgs` and their `*ById` maps return **age-filtered**
  results via `ageGate.isVisible(minAge:)`.
- Recompute trigger: when the cached bracket changes (initial `refresh()` resolves or the
  user re-verifies), the filtered views recompute and SwiftUI refreshes.
- `EventsView`'s `schedulePipelineKey` incorporates the bracket so its cached
  filter+group schedule recomputes when the age result changes.
- **Coverage (single chokepoint):** Schedule, All Content, Orgs list, Global Search, and the
  combined-bookmark schedule all read these collections, so all are covered at once. Detail
  views reached by id resolve against the filtered `*ById`, so a hidden item's detail does
  not open.

### 4. Trigger + Settings

- **Up front:** `ContentView` (or `InfoView`) `.task` calls `ageGate.refresh()` on launch.
  The system presents its sheet the first time or returns silently if already shared.
- **Settings → "Age Verification":** shows status (`Verified 18+` / `Not verified` /
  `Unavailable on this iOS`) and a **Verify Age** button calling
  `ageGate.refresh(forcePrompt: true)`. Uses the existing `settingsCard` styling.

### 5. Error handling

- All failure/decline/indeterminate paths fold into `AgeRangeResult(nil, nil)` → fail open.
- The Apple call is wrapped so a thrown error is logged (`Log.app`) and treated as unknown.
- No user-facing error surface; the Settings status line reflects the current known state.

## Testing

- Unit-test `AgeGate.isVisible(minAge:)` against a fake `AgeRangeProviding`:
  - `minAge == nil` (and default `nil`) → visible.
  - default flipped to a value → gates a nil-min item.
  - `upperBound` below / equal / above `minAge` for gates 13/16/18.
  - unknown bounds (declined/error/pre-26) → visible (fail open).
- The Declared Age Range call itself (system UI) is not unit-tested; it lives in the real
  provider behind the protocol.

## API verification (implementation-time)

The exact `DeclaredAgeRange` symbol names — the request service type, the request method
signature, and the response/enum cases — are from the iOS 26 API and must be confirmed
against current Apple documentation when the real provider is implemented. The
`AgeRangeProviding` protocol confines this uncertainty to one adapter; the rest of the
feature depends only on `AgeRangeResult`.

## Rollout notes

- No deployment-target change (stays iOS 17.0). The real provider is gated by
  `if #available(iOS 26, *)`.
- Backward-compatible data: documents without `visible_age_min` behave exactly as today.
