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
        #if DEBUG
        // Debug harness: when a simulated band is active, honor it instead
        // of querying the provider, so the override survives the up-front
        // launch refresh (and relaunches) during testing.
        if UserDefaults.standard.bool(forKey: Self.debugOverrideKey) {
            lowerBound = UserDefaults.standard.object(forKey: Self.debugLowerKey) as? Int
            upperBound = UserDefaults.standard.object(forKey: Self.debugUpperKey) as? Int
            return
        }
        #endif
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

    #if DEBUG
    // MARK: - Debug band override (test harness, DEBUG builds only)
    //
    // Lets a tester force the effective declared-age band from Settings so
    // gated content can be reviewed without the real iOS 26 flow. The band
    // is persisted and re-applied by refresh(), so it sticks across the
    // launch query and relaunches until cleared.
    private static let debugOverrideKey = "ageGate.debug.override.v1"
    private static let debugLowerKey = "ageGate.debug.lower.v1"
    private static let debugUpperKey = "ageGate.debug.upper.v1"

    var debugOverrideActive: Bool { UserDefaults.standard.bool(forKey: Self.debugOverrideKey) }

    /// Force the effective band. Caller should re-run the filter afterward
    /// (see InfoViewModel.debugSetAgeBracket).
    func debugSetBracket(lower: Int?, upper: Int?) {
        lowerBound = lower
        upperBound = upper
        let d = UserDefaults.standard
        d.set(true, forKey: Self.debugOverrideKey)
        d.set(lower, forKey: Self.debugLowerKey)
        d.set(upper, forKey: Self.debugUpperKey)
        // Mirror into the normal cache so first-frame filtering matches.
        d.set(lower, forKey: Self.lowerKey)
        d.set(upper, forKey: Self.upperKey)
    }

    /// Turn the override off and return to the real/device-driven flow.
    func debugClearOverride() {
        let d = UserDefaults.standard
        d.removeObject(forKey: Self.debugOverrideKey)
        d.removeObject(forKey: Self.debugLowerKey)
        d.removeObject(forKey: Self.debugUpperKey)
    }
    #endif
}

// MARK: - iOS 26 Declared Age Range adapter
//
// API confirmed against Apple's current developer documentation for the
// `DeclaredAgeRange` framework ("Requesting people share their age range
// with your app", AgeRangeService / AgeRangeService.Response /
// AgeRangeService.AgeRange), July 2026:
//   - `AgeRangeService.shared.requestAgeRange(ageGates:_:_:in:) async throws
//     -> AgeRangeService.Response` takes UP TO THREE separate `Int`/`Int?`
//     gate parameters (not an array) plus a presentation anchor
//     (`UIViewController` on iOS/iPadOS/Mac Catalyst, `NSWindow` on macOS).
//   - `Response` has cases `.sharing(AgeRangeService.AgeRange)` and
//     `.declinedSharing`.
//   - `AgeRangeService.AgeRange` exposes `lowerBound: Int?` and
//     `upperBound: Int?`.
//   - Failures throw `AgeRangeService.Error`.
// `AgeGateConfig.requestedGates` is exactly 3 entries ([13, 16, 18]), which
// matches the API's 3-gate maximum.
#if canImport(DeclaredAgeRange)
import DeclaredAgeRange
import UIKit

/// Real adapter over Apple's Declared Age Range API. Maps the response to
/// AgeRangeResult; any decline/error/indeterminate → .unknown (fail open).
@available(iOS 26, *)
struct DeclaredAgeRangeProvider: AgeRangeProviding {
    func requestRange(gates: [Int], forcePrompt: Bool) async -> AgeRangeResult {
        guard let anchor = await Self.presentationAnchor() else {
            Log.app.error("age range request failed: no presentation anchor available")
            return .unknown
        }
        guard let first = gates.first else { return .unknown }
        let second = gates.count > 1 ? gates[1] : nil
        let third = gates.count > 2 ? gates[2] : nil
        do {
            let response = try await AgeRangeService.shared.requestAgeRange(
                ageGates: first, second, third, in: anchor
            )
            switch response {
            case .sharing(let range):
                return AgeRangeResult(lowerBound: range.lowerBound,
                                      upperBound: range.upperBound)
            case .declinedSharing:
                return .unknown
            @unknown default:
                return .unknown
            }
        } catch {
            Log.app.error("age range request failed: \(String(describing: error), privacy: .public)")
            return .unknown
        }
    }

    /// The system sheet needs a presentation anchor; there is no existing
    /// convention in this codebase for finding one, so we look up the key
    /// window's root view controller directly.
    @MainActor
    private static func presentationAnchor() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?.rootViewController
    }
}
#endif

extension AgeGate {
    /// Picks the real provider on iOS 26+, no-op otherwise (including when
    /// building against an SDK that predates iOS 26 and doesn't ship the
    /// `DeclaredAgeRange` module at all).
    static func makeDefault() -> AgeGate {
        #if canImport(DeclaredAgeRange)
        if #available(iOS 26, *) {
            return AgeGate(provider: DeclaredAgeRangeProvider())
        }
        #endif
        return AgeGate(provider: NoopAgeRangeProvider())
    }
}
