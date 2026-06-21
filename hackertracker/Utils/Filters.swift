//
//  Filters.swift
//  hackertracker
//
//  Created by Caleb Kinney on 7/13/23.
//

import Foundation

class Filters: ObservableObject {
    @Published var filters: Set<Int>

    init(filters: Set<Int>) {
        self.filters = filters
    }
}

/// Independent filter set for the Speakers list. Distinct class from
/// `Filters` so both can sit in the SwiftUI environment without type
/// collision — `Filters` continues to drive Schedule + All Content
/// while `SpeakerFiltersStore` is read only by SpeakersView and the
/// speaker filter sheet.
final class SpeakerFiltersStore: ObservableObject {
    @Published var filters: Set<Int>

    init(filters: Set<Int> = []) {
        self.filters = filters
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
    static let excludedTagTypeLabels: Set<String> = ["Skill Level", "Modality"]
}
