# Per-Section Any/All Filters — Design Spec

**Date:** 2026-07-20
**Status:** Approved for planning
**Feature branch:** `feature/filters-and-feedback`

## Summary

Make the Schedule and All Content filters smarter: instead of one global Any/All that
applies to every selected chip, give **each tagtype section its own Any/All mode**, and
combine sections with **AND**. This lets a user express, e.g., "Contests (Type) under
organizer A **or** B (Organizer, Any)" — a query the current single-mode model can't form.

## Decisions

| # | Decision | Choice |
|---|----------|--------|
| 1 | Cross-section combination | **AND** across active sections; Any/All is configurable *within* each section. |
| 2 | Pseudo-toggles (Bookmarks / Custom Events / Has Notes) | Each remains its own **AND** constraint; no Any/All (single concepts). |
| 3 | Per-section control visibility | Show the section's Any/All control **only when ≥2 chips are selected** in that section. |
| 4 | Default section mode | `.any`. |
| 5 | Scope | **Schedule + All Content only.** Speakers and Merch keep their existing single-mode pickers. |

## Current state (verified)

- Schedule (`EventsView`) and All Content (`ContentListView`) present the **same** filter
  sheet `EventFilters` (`Views/FiltersView.swift`), share the same `Filters` store, and
  read the same `@AppStorage(AppStorageKeys.filterMatchMode)` — one global Any/All.
- The predicate lives in `Utils/ModelExt.swift` as `filters(...)` overloads on `[Event]`
  and `[Content]`. Today all selected real tags are flattened into one OR bucket, and the
  global `mode` only distinguishes the four buckets (tags / bookmarks / custom / hasNotes).
- `FilterMatchMode` (`.any`/`.all`) and `MatchModePickerRow` already exist and are reused
  by Speakers/Merch — those are out of scope and unchanged.

## Design

### 1. Section-mode model

Add a lightweight store for per-tagtype modes, shared by Schedule + All Content (mirroring
how they already share `filterMatchMode`):

```swift
/// Per-tagtype-section Any/All modes for the Schedule + All Content filter.
/// Persisted as JSON [tagTypeId: "any"|"all"] under one AppStorage key.
struct SectionFilterModes {
    private(set) var modes: [Int: FilterMatchMode]   // tagTypeId -> mode
    func mode(for tagTypeId: Int) -> FilterMatchMode  // default .any
    mutating func setMode(_ mode: FilterMatchMode, for tagTypeId: Int)
    // Codable to/from the AppStorage JSON string.
}
```

Stored under a new key `AppStorageKeys.sectionFilterModes` (JSON string). The old
`filterMatchMode` key is retired for Schedule/All Content (left in `AppStorageKeys` only if
Speakers/Merch still use their own keys — they use `filterMatchModeSpeakers`/`Merch`, so the
plain `filterMatchMode` key becomes unused and is removed).

### 2. Predicate change (`ModelExt.swift`)

Both `[Event].filters(...)` and `[Content].filters(...)` replace the single
`mode: FilterMatchMode` parameter with `sectionModes: [Int: FilterMatchMode]`. New logic:

1. Group the selected real tag ids by their tagtype → `[tagTypeId: Set<tagId>]`.
2. For each **active** tagtype (≥1 selected tag), compute a per-section match:
   - `.any` → the item has **any** of that section's selected tags.
   - `.all` → the item has **all** of that section's selected tags.
3. Combine all active tagtype sections with **AND**.
4. Combine the pseudo constraints (Bookmarks, Custom, Has Notes) — each, when active, is an
   additional **AND** constraint (must be bookmarked / custom / have notes).
5. No selection anywhere → return everything (unchanged).

This is a behavior change from today's global OR-bucket + single Any/All. It is intentional
and is the point of the feature.

### 3. Filter sheet UI (`FiltersView.swift` / `EventFilters`)

- Remove the single top-of-sheet `MatchModePickerRow`.
- In each tagtype section header, render a compact **Any / All** segmented control, bound to
  `SectionFilterModes.mode(for: tagTypeId)`. Show it **only when that section has ≥2 chips
  selected**; hide otherwise (a lone selection has no Any/All meaning).
- Pseudo-toggle rows (Bookmarks / Custom / Has Notes) get no control.
- The live "matched count" label continues to reflect the composed predicate.

### 4. Consumers

- `EventsView` schedule pipeline: pass `sectionModes` into `filters(...)`; include the
  section-modes identity in `schedulePipelineKey` so the cached result recomputes when a
  section mode changes.
- `ContentListView`: pass `sectionModes` into its `filters(...)` / grouping call.

## Testing

Unit tests on the predicate (no UI), for both `[Event]` and `[Content]`:
- Single section, `.any` vs `.all` (item with one vs both tags).
- Two sections combine with AND (must satisfy both).
- Pseudo-toggle (e.g. Bookmarks) AND-combines with a tag section.
- Empty selection → all returned.
- The "Contests under organizer A or B" worked example.

## Non-goals

- No change to Speakers or Merch filtering.
- No OR-across-sections mode, no global override toggle.
- No change to which chips exist or how tagtypes are sourced.
