//
//  AISummaryAvailability.swift
//  hackertracker
//
//  Single source of truth for "can we use Apple Intelligence to summarize
//  talk descriptions on this build / OS / device?" Every call site that
//  touches FoundationModels routes through this gate so we don't scatter
//  `#available` / `canImport` checks throughout the view layer.
//

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

@MainActor
enum AISummaryAvailability {
    /// Compile-time + runtime check. Returns true when the FoundationModels
    /// framework is linkable AND we're on iOS 26+ AND the on-device
    /// language model reports itself ready to serve requests.
    ///
    /// This is the capability gate. The user-facing feature flag (the
    /// `aiSummaries` @AppStorage toggle) is checked separately at each
    /// call site so we can keep the flag set even when the device
    /// temporarily can't satisfy a request (e.g. Apple Intelligence is
    /// downloading the model or the user is in low-power mode).
    static var isSupported: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return SystemLanguageModel.default.availability == .available
        }
        #endif
        return false
    }

    /// Whether the AI summary path *might* be available later even if it
    /// isn't right now (model still loading, device assets downloading,
    /// etc). Useful for deciding whether to hide a Settings row entirely
    /// (`isSupported == false && isPossiblyAvailable == false`) vs. show
    /// it disabled with an explanatory caption.
    static var isPossiblyAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) { return true }
        #endif
        return false
    }
}
