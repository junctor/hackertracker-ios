//
//  ModelExt.swift
//  hackertracker
//
//  Created by Caleb Kinney on 6/2/23.
//

import Foundation

/// Perf D: shared DateFormatter pool for ModelExt groupers.
/// Single-instance + main-actor-only mutation.
@MainActor
private enum ModelExtFormatters {
    static let eventDay: DateFormatter = {
        let f = DateFormatter()
        // Weekday + month + day, e.g. "Thursday, August 7" (rendered
        // uppercased in the schedule's day-section headers).
        f.dateFormat = "EEEE, MMMM d"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
}

extension [TagType] {
    func tags(category: String) -> [Tag] {
        var retArray: [Tag] = []
        for tagtype in filter({ $0.category == category }) {
            retArray.append(contentsOf: tagtype.tags)
        }
        return retArray
    }
}

extension [Content] {
    func filters(
        typeIds: Set<Int>,
        bookmarks: Set<Int32>,
        tagTypes: [TagType],
        contentNoteIDs: Set<Int32> = [],
        sectionModes: [Int: FilterMatchMode] = [:]
    ) -> Self {
        if typeIds.isEmpty {
            return self
        } else {
            var selectedByType: [Int: [Int]] = [:]
            for typeId in typeIds where !PseudoTagID.all.contains(typeId) {
                if let tagType = tagTypes.first(where: { $0.tags.contains(where: { $0.id == typeId }) }) {
                    if selectedByType.keys.contains(tagType.id) {
                        selectedByType[tagType.id]?.append(typeId)
                    } else {
                        selectedByType[tagType.id] = [typeId]
                    }
                }
            }

            return filter { content in
                if !selectedByType.isEmpty,
                   !sectionFilterMatch(tagIds: content.tagIds, selectedByType: selectedByType, sectionModes: sectionModes) {
                    return false
                }
                if typeIds.contains(PseudoTagID.bookmarks), !bookmarks.contains(Int32(content.id)) { return false }
                if typeIds.contains(PseudoTagID.hasNotes), !contentNoteIDs.contains(Int32(content.id)) { return false }
                return true
            }
        }
    }
}

// Sentinel pseudo-tag ids used by the filter sheet to compose with
// real tags. Kept in sync with FilterRow row literals.
enum PseudoTagID {
    static let bookmarks: Int = 1337
    static let customEvents: Int = 1338
    static let hasNotes: Int = 1339
    /// Convenience set so callers can `filters.subtracting(PseudoTagID.all)`
    /// to recover the real-tag ids.
    static let all: Set<Int> = [bookmarks, customEvents, hasNotes]
}

/// Filter-chip composition mode, selectable per tag section. Persisted as
/// JSON (tagTypeId -> raw mode) under @AppStorage(AppStorageKeys.sectionFilterModes)
/// via `SectionFilterModes`; FiltersView writes it and predicate consumers
/// (`sectionFilterMatch`, `[Event].filters`, `[Content].filters`) read it.
enum FilterMatchMode: String, CaseIterable {
    case any = "any"
    case all = "all"
    static let defaultRaw: String = FilterMatchMode.any.rawValue
    init(rawOrDefault raw: String) {
        self = FilterMatchMode(rawValue: raw) ?? .any
    }
}

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

extension [Event] {
    /* func types() -> [Int: EventType] {
        return reduce(into: [:]) { tags, event in
            tags[event.type.id] = event.type
        }
    } */
    
    func filters(
        typeIds: Set<Int>,
        bookmarks: Set<Int32>,
        tagTypes: [TagType],
        eventNoteIDs: Set<Int32> = [],
        contentNoteIDs: Set<Int32> = [],
        sectionModes: [Int: FilterMatchMode] = [:]
    ) -> Self {
        if typeIds.isEmpty {
            return self
        } else {
            var selectedByType: [Int: [Int]] = [:]
            for typeId in typeIds where !PseudoTagID.all.contains(typeId) {
                if let tagType = tagTypes.first(where: { $0.tags.contains(where: { $0.id == typeId }) }) {
                    if selectedByType.keys.contains(tagType.id) {
                        selectedByType[tagType.id]?.append(typeId)
                    } else {
                        selectedByType[tagType.id] = [typeId]
                    }
                }
            }
            let useBookmarks = typeIds.contains(PseudoTagID.bookmarks)
            let useCustom = typeIds.contains(PseudoTagID.customEvents)
            let useHasNotes = typeIds.contains(PseudoTagID.hasNotes)
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
        }
    }
    
    @MainActor
    func eventDayGroup(showLocaltime: Bool, conference: Conference?) -> [(key: String, value: [Event])] {
        // Perf D: reuse a single DateFormatter across calls; the
        // function is @MainActor so concurrent mutation is impossible.
        let formatter = ModelExtFormatters.eventDay
        // Phase 4: single source of truth in ClockService; no more hardcoded LA fallback.
        formatter.timeZone = ClockService.resolveTimeZone(conference: conference, showLocaltime: showLocaltime)
        
        // Perf D: sort each day's events once here so consumers
        // (EventData's ForEach, the scroll-command handlers) can
        // iterate directly instead of re-sorting per render.
        let eventDict = Dictionary(
            grouping: self,
            by: {
                formatter.string(from: $0.beginTimestamp)
            }
        ).mapValues { day in
            day.sorted { $0.beginTimestamp < $1.beginTimestamp }
        }
        return eventDict.sorted {
            ($0.value.first?.beginTimestamp ?? Date()) < ($1.value.first?.beginTimestamp ?? Date())
        }
    }
}
