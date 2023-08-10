//
//  Searchable.swift
//  hackertracker
//
//  Created by Caleb Kinney on 7/4/23.
//

import Foundation

extension [Event] {
    func search(text: String) -> Self {
        text.isEmpty ? self : self.filter { $0.title.lowercased().contains(text.lowercased()) || $0.description.lowercased().contains(text.lowercased()) }
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
