//
//  Searchable.swift
//  hackertracker
//
//  Created by Caleb Kinney on 7/4/23.
//

import Foundation

extension [Event] {
    /// Search title + description. Use the overload with `speakers:` when you
    /// want to also match by presenter name.
    func search(text: String) -> Self {
        text.isEmpty ? self : self.filter { $0.title.lowercased().contains(text.lowercased()) || $0.description.lowercased().contains(text.lowercased()) }
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
        text.isEmpty ? self : self.filter { $0.title.lowercased().contains(text.lowercased()) }
    }
}

extension [Speaker] {
    func search(text: String) -> Self {
        text.isEmpty ? self : self.filter { $0.name.lowercased().contains(text.lowercased()) || $0.description.lowercased().contains(text.lowercased()) }
    }
}

extension [Content] {
    func search(text: String) -> Self {
        text.isEmpty ? self : self.filter { $0.title.lowercased().contains(text.lowercased()) || $0.description.lowercased().contains(text.lowercased()) }
    }
}

extension [Organization] {
    func search(text: String) -> Self {
        text.isEmpty ? self : self.filter { $0.name.lowercased().contains(text.lowercased()) }
    }
}

extension [FAQ] {
    func search(text: String) -> Self {
        text.isEmpty ? self : self.filter { $0.question.lowercased().contains(text.lowercased()) || $0.answer.lowercased().contains(text.lowercased()) }
    }
}

extension [Article] {
    func search(text: String) -> Self {
        text.isEmpty ? self : self.filter { $0.name.lowercased().contains(text.lowercased()) || $0.text.lowercased().contains(text.lowercased()) }
    }
}

extension [Document] {
    func search(text: String) -> Self {
        text.isEmpty ? self: self.filter { $0.title.lowercased().contains(text.lowercased()) ||
            $0.body.lowercased().contains(text.lowercased())
        }
    }
}
