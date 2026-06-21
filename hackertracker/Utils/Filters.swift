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
