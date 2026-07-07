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
        f.dateFormat = "MMMM d"
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
    func filters(typeIds: Set<Int>, bookmarks: Set<Int32>, tagTypes: [TagType]) -> Self {
        if typeIds.isEmpty {
            return self
        } else {
            var filterTypes: [Int: [Int]] = [:]
            for typeId in typeIds {
                if let tagType = tagTypes.first(where: { $0.tags.contains(where: { $0.id == typeId }) }) {
                    if filterTypes.keys.contains(tagType.id) {
                        filterTypes[tagType.id]?.append(typeId)
                    } else {
                        filterTypes[tagType.id] = [typeId]
                    }
                }
            }
            
            if typeIds.contains(1337) {
                return filter {
                    isFiltered(tagIds: $0.tagIds, filterTypes: filterTypes)
                    && bookmarks.contains(Int32($0.id))
                }
            } else {
                return filter { isFiltered(tagIds: $0.tagIds, filterTypes: filterTypes) }
            }
        }
    }
    
    func isFiltered(tagIds: [Int], filterTypes: [Int: [Int]]) -> Bool {
        var results: [Bool] = []
        for ft in filterTypes {
            var myR = false
            if ft.value.contains(where: { tagIds.contains($0) }) {
                myR = true
            }
            results.append(myR)
        }
        if results.contains(false) {
            return false
        } else {
            return true
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

/// Filter-chip composition mode. Read from @AppStorage(AppStorageKeys.filterMatchMode)
/// by FiltersView (writes) and the predicate consumers (reads). Storing
/// the raw string lets us swap it cleanly via @AppStorage on multiple
/// independent views without an envelope object.
enum FilterMatchMode: String, CaseIterable {
    case any = "any"
    case all = "all"
    static let defaultRaw: String = FilterMatchMode.any.rawValue
    init(rawOrDefault raw: String) {
        self = FilterMatchMode(rawValue: raw) ?? .any
    }
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
        mode: FilterMatchMode = .any
    ) -> Self {
        if typeIds.isEmpty {
            return self
        } else {
            var filterTypes: [Int: [Int]] = [:]
            for typeId in typeIds {
                if let tagType = tagTypes.first(where: { $0.tags.contains(where: { $0.id == typeId }) }) {
                    if filterTypes.keys.contains(tagType.id) {
                        filterTypes[tagType.id]?.append(typeId)
                    } else {
                        filterTypes[tagType.id] = [typeId]
                    }
                }
            }
            // Each chip category contributes independently. In .any
            // mode (OR) a row survives when ANY active category
            // matches it. In .all mode (AND) a row must satisfy
            // EVERY active category. "Active" = at least one chip
            // from that category is selected; categories with no
            // selection don't constrain the result either way.
            let realTagIDs = Set(filterTypes.values.flatMap { $0 })
            let useTags = !realTagIDs.isEmpty
            let useBookmarks = typeIds.contains(PseudoTagID.bookmarks)
            let useCustom = typeIds.contains(PseudoTagID.customEvents)
            let useHasNotes = typeIds.contains(PseudoTagID.hasNotes)
            return filter { event in
                let tagMatch: Bool? = useTags
                    ? event.tagIds.contains(where: { realTagIDs.contains($0) })
                    : nil
                let bookmarkMatch: Bool? = useBookmarks
                    ? bookmarks.contains(Int32(event.id))
                    : nil
                let customMatch: Bool? = useCustom
                    ? (event.customEventID != nil)
                    : nil
                let hasNotesMatch: Bool? = useHasNotes
                    ? (eventNoteIDs.contains(Int32(event.id))
                       || contentNoteIDs.contains(Int32(event.contentId)))
                    : nil
                let checks = [tagMatch, bookmarkMatch, customMatch, hasNotesMatch].compactMap { $0 }
                guard !checks.isEmpty else { return true }
                switch mode {
                case .any: return checks.contains(true)
                case .all: return checks.allSatisfy { $0 }
                }
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
    
    func isFiltered(tagIds: [Int], filterTypes: [Int: [Int]]) -> Bool {
        var results: [Bool] = []
        for ft in filterTypes {
            var myR = false
            if ft.value.contains(where: { tagIds.contains($0) }) {
                myR = true
            }
            results.append(myR)
        }
        if results.contains(false) {
            return false
        } else {
            return true
        }
    }
}
