//
//  Filters.swift
//  hackertracker
//
//  Created by Caleb Kinney on 7/13/23.
//

import Foundation

/// Shared persistence helpers used by every filter store below.
private enum FilterStorePersistence {
    static func loadIntSet(forKey key: String) -> Set<Int>? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(Set<Int>.self, from: data)
    }

    static func loadStringSet(forKey key: String) -> Set<String>? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(Set<String>.self, from: data)
    }

    static func save<T: Encodable>(_ value: T, forKey key: String) {
        if let data = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

class Filters: ObservableObject {
    private static let userDefaultsKey = "filtersStore.schedule.v1"
    @Published var filters: Set<Int> {
        didSet { FilterStorePersistence.save(filters, forKey: Self.userDefaultsKey) }
    }

    init(filters: Set<Int>) {
        // Persisted value (if any) wins over the caller's default.
        // Survives cold launch so users don't have to re-pick chips
        // every time they relaunch the app.
        self.filters = FilterStorePersistence.loadIntSet(forKey: Self.userDefaultsKey) ?? filters
    }
}

/// Independent filter set for the Speakers list. Distinct class from
/// `Filters` so both can sit in the SwiftUI environment without type
/// collision — `Filters` continues to drive Schedule + All Content
/// while `SpeakerFiltersStore` is read only by SpeakersView and the
/// speaker filter sheet.
final class SpeakerFiltersStore: ObservableObject {
    private static let userDefaultsKey = "filtersStore.speakers.v1"
    @Published var filters: Set<Int> {
        didSet { FilterStorePersistence.save(filters, forKey: Self.userDefaultsKey) }
    }

    init(filters: Set<Int> = []) {
        self.filters = FilterStorePersistence.loadIntSet(forKey: Self.userDefaultsKey) ?? filters
    }
}

/// Independent filter set for the Merch (Products) list. Holds the
/// selected size labels rather than tag ids; otherwise identical to
/// the other stores. Hoisted out of ProductsView's @State so the
/// selection survives tab switches in addition to cold launches.
final class MerchFiltersStore: ObservableObject {
    private static let userDefaultsKey = "filtersStore.merch.v1"
    @Published var sizes: Set<String> {
        didSet { FilterStorePersistence.save(sizes, forKey: Self.userDefaultsKey) }
    }

    init(sizes: Set<String> = []) {
        self.sizes = FilterStorePersistence.loadStringSet(forKey: Self.userDefaultsKey) ?? sizes
    }
}

/// Configuration knobs shared between `SpeakerRow` (chip strip) and
/// `SpeakersView` (filter sheet + filter pipeline) so all three stay
/// consistent.
enum SpeakerListConfig {
    /// Tagtype labels intentionally hidden from the speakers list.
    /// These dimensions live on events (talks have a skill level and a
    /// modality) but don't read as useful speaker metadata — a
    /// speaker isn't "Beginner" or "Hybrid", their *talk* is. Drop
    /// them from both the chip rollup and the filter sheet so users
    /// see only the categorical/organizational signals.
    /// "Tool" is included on the same logic: events tagged "Tool" are
    /// tooling releases / demos, but the speaker isn't a tool.
    static let excludedTagTypeLabels: Set<String> = ["Skill Level", "Modality", "Tool"]
}
