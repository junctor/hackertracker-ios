//
//  AgeGate.swift
//  hackertracker
//
//  Age-restriction gate backed by Apple's Declared Age Range API (iOS 26+).
//  On iOS < 26 there is no provider, so nothing is ever hidden.
//

import Foundation
import SwiftUI

enum AgeGateConfig {
    /// Applied when an item has no explicit visible_age_min.
    /// nil = no minimum. Change here to flip the default policy app-wide.
    static let defaultMinAge: Int? = nil
    /// Age gates requested from the Declared Age Range API.
    static let requestedGates: [Int] = [13, 16, 18]
}

/// Coarse age bracket. nil bounds = unknown (declined / error / iOS < 26).
struct AgeRangeResult {
    let lowerBound: Int?
    let upperBound: Int?
    static let unknown = AgeRangeResult(lowerBound: nil, upperBound: nil)
}

/// Injectable source of the declared age range. The real iOS-26 adapter is
/// added in Task 3; tests and iOS < 26 use NoopAgeRangeProvider.
protocol AgeRangeProviding: Sendable {
    func requestRange(gates: [Int], forcePrompt: Bool) async -> AgeRangeResult
}

struct NoopAgeRangeProvider: AgeRangeProviding {
    func requestRange(gates: [Int], forcePrompt: Bool) async -> AgeRangeResult { .unknown }
}

@Observable
@MainActor
final class AgeGate {
    private(set) var lowerBound: Int?
    private(set) var upperBound: Int?
    @ObservationIgnored private let provider: AgeRangeProviding

    init(provider: AgeRangeProviding = NoopAgeRangeProvider()) {
        self.provider = provider
        // Restore the cached bracket so filtering applies before refresh().
        let d = UserDefaults.standard
        self.lowerBound = d.object(forKey: Self.lowerKey) as? Int
        self.upperBound = d.object(forKey: Self.upperKey) as? Int
    }

    private static let lowerKey = "ageGate.lowerBound.v1"
    private static let upperKey = "ageGate.upperBound.v1"

    func refresh(forcePrompt: Bool = false) async {
        let result = await provider.requestRange(gates: AgeGateConfig.requestedGates,
                                                  forcePrompt: forcePrompt)
        lowerBound = result.lowerBound
        upperBound = result.upperBound
        let d = UserDefaults.standard
        d.set(result.lowerBound, forKey: Self.lowerKey)
        d.set(result.upperBound, forKey: Self.upperKey)
    }

    /// Fail-open decision: hide ONLY when the user's maximum possible age is
    /// below the item's minimum. Everything else is visible.
    func isVisible(minAge rawMin: Int?) -> Bool {
        let minAge = rawMin ?? AgeGateConfig.defaultMinAge
        guard let minAge else { return true }        // no minimum
        guard let upper = upperBound else { return true }  // no signal → fail open
        return upper >= minAge
    }
}
