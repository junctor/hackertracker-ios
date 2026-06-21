//
//  Searchable.swift
//  hackertracker
//
//  Created by Caleb Kinney on 7/4/23.
//

import Foundation

// Perf D: Every overload previously called `.lowercased()` on the haystack
// *and* on the needle inside the filter closure — once per item, twice per
// field per item. With 500–1000 items per list and a normal typing cadence
// that's tens of thousands of String allocations per keystroke. We now
// lowercase the needle once and use `.range(of:options:.caseInsensitive)`
// against the original strings, matching the pattern already used by the
// Event+speakers overload.
private func _searchMatches(_ haystack: String, needle: String) -> Bool {
    haystack.range(of: needle, options: .caseInsensitive) != nil
}

extension [Event] {
    func search(text: String) -> Self {
        guard !text.isEmpty else { return self }
        let needle = text
        return filter { _searchMatches($0.title, needle: needle) || _searchMatches($0.description, needle: needle) }
    }

    /// Bugfix: previously search ignored presenter names because Event.people
    /// is `[Person]` (id+sortOrder only) while names live in `viewModel.speakers`.
    /// Build a per-call id->name index and match against it.
    func search(text: String, speakers: [Speaker]) -> Self {
        guard !text.isEmpty else { return self }
        let needle = text.lowercased()
        // Index speaker names once per call instead of O(events * speakers).
        let speakerNameById: [Int: String] = Dictionary(
            uniqueKeysWithValues: speakers.map { ($0.id, $0.name.lowercased()) }
        )
        return self.filter { event in
            if event.title.lowercased().contains(needle) { return true }
            if event.description.lowercased().contains(needle) { return true }
            for person in event.people {
                if let name = speakerNameById[person.id], name.contains(needle) {
                    return true
                }
            }
            return false
        }
    }
}

extension [Product] {
    func search(text: String) -> Self {
        guard !text.isEmpty else { return self }
        return filter { _searchMatches($0.title, needle: text) }
    }
}

extension [Speaker] {
    func search(text: String) -> Self {
        guard !text.isEmpty else { return self }
        return filter { _searchMatches($0.name, needle: text) || _searchMatches($0.description, needle: text) }
    }

    /// Speaker search with the speaker's event titles as additional
    /// match surface. Passing an `eventsById` dict lets the search
    /// match against talk titles too — useful when the user is
    /// looking up "who's giving the BadgeLife panel" rather than the
    /// speaker by name. Falls back gracefully when an event id isn't
    /// in the dict (cold load), in which case that event just
    /// doesn't contribute to the match for this speaker.
    func search(text: String, eventsById: [Int: Event]) -> Self {
        guard !text.isEmpty else { return self }
        return filter { speaker in
            if _searchMatches(speaker.name, needle: text)
                || _searchMatches(speaker.description, needle: text) {
                return true
            }
            return speaker.eventIds.contains { id in
                guard let title = eventsById[id]?.title else { return false }
                return _searchMatches(title, needle: text)
            }
        }
    }
}

extension [Content] {
    func search(text: String) -> Self {
        guard !text.isEmpty else { return self }
        return filter { _searchMatches($0.title, needle: text) || _searchMatches($0.description, needle: text) }
    }
}

extension [Organization] {
    func search(text: String) -> Self {
        guard !text.isEmpty else { return self }
        return filter { _searchMatches($0.name, needle: text) }
    }
}

extension [FAQ] {
    func search(text: String) -> Self {
        guard !text.isEmpty else { return self }
        return filter { _searchMatches($0.question, needle: text) || _searchMatches($0.answer, needle: text) }
    }
}

extension [Article] {
    func search(text: String) -> Self {
        guard !text.isEmpty else { return self }
        return filter { _searchMatches($0.name, needle: text) || _searchMatches($0.text, needle: text) }
    }
}

extension [Document] {
    func search(text: String) -> Self {
        guard !text.isEmpty else { return self }
        return filter { _searchMatches($0.title, needle: text) || _searchMatches($0.body, needle: text) }
    }
}
