//
//  ClockService.swift
//  hackertracker
//
//  Phase 4: centralized timezone resolution. Removes the previous
//  hardcoded `America/Los_Angeles` / `PDT` literals scattered across
//  DateFormatterUtility, ModelExt, SettingsView, ConferencesView, and
//  EventsView. Conference.timezone (a Firestore-driven String?) is the
//  source of truth for which timezone the schedule renders in; the
//  `showLocaltime` @AppStorage toggle overrides to device-local.
//

import Foundation

@MainActor
enum ClockService {
    /// Resolve the timezone the UI should display for the current
    /// conference + user preference. Priority:
    /// 1. `showLocaltime == true` -> device-current
    /// 2. `conference.timezone` (e.g. "America/Los_Angeles") if non-nil and valid
    /// 3. Device-current as a safe fallback (was hardcoded "America/Los_Angeles"
    ///    before Phase 4 — that broke any conference not in the Las Vegas zone).
    static func resolveTimeZone(conference: Conference?, showLocaltime: Bool) -> TimeZone {
        if showLocaltime { return .current }
        if let identifier = conference?.timezone,
           !identifier.isEmpty,
           let tz = TimeZone(identifier: identifier) {
            return tz
        }
        return .current
    }

    /// Update the shared DateFormatterUtility's formatters to render in the
    /// timezone resolved from the given (conference, showLocaltime) pair.
    static func apply(conference: Conference?, showLocaltime: Bool) {
        let tz = resolveTimeZone(conference: conference, showLocaltime: showLocaltime)
        DateFormatterUtility.shared.update(tz: tz)
    }
}
