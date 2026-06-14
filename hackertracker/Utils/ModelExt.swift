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
        contentNoteIDs: Set<Int32> = []
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
            // Pseudo-tag OR-composition. A row survives when ANY
            // selected chip matches it — "Has Notes" + "Custom
            // Events" returns the union, not the (usually-empty)
            // intersection. Real-tag chips use a plain set
            // intersection rather than the per-tag-type AND in
            // isFiltered(), because OR semantics don't require
            // hitting EVERY tag type — just any selected tag id.
            let realTagIDs = Set(filterTypes.values.flatMap { $0 })
            return filter { event in
                let tagMatch = !realTagIDs.isEmpty
                    && event.tagIds.contains(where: { realTagIDs.contains($0) })
                let bookmarkMatch = typeIds.contains(PseudoTagID.bookmarks)
                    && bookmarks.contains(Int32(event.id))
                let customMatch = typeIds.contains(PseudoTagID.customEvents)
                    && event.customEventID != nil
                let hasNotesMatch = typeIds.contains(PseudoTagID.hasNotes) && (
                    eventNoteIDs.contains(Int32(event.id))
                    || contentNoteIDs.contains(Int32(event.contentId))
                )
                return tagMatch || bookmarkMatch || customMatch || hasNotesMatch
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
        
        let eventDict = Dictionary(
            grouping: self,
            by: {
                formatter.string(from: $0.beginTimestamp)
            }
        )
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
