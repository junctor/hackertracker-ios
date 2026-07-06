//
//  AppStorageKeys.swift
//  hackertracker
//

import Foundation

/// Central registry of `@AppStorage` / `UserDefaults` key strings used throughout the app.
///
/// All persisted preference keys should be referenced via these constants instead of
/// raw string literals. This gives compile-time checking (a typo becomes a build error
/// rather than silently creating a brand-new, disconnected setting) and makes it possible
/// to find every read/write site for a given key with a single "Find Usages".
///
/// The string VALUE of each constant must remain byte-identical to the original literal —
/// these are persisted `UserDefaults` keys, and changing a value would orphan users'
/// previously saved settings.
enum AppStorageKeys {
    static let colorMode = "colorMode"
    static let notifyAt = "notifyAt"
    static let showLocaltime = "showLocaltime"
    static let show24hourtime = "show24hourtime"
    static let filterMatchMode = "filterMatchMode"
    static let easterEgg = "easterEgg"
    static let aiSummaries = "aiSummaries"
    static let showNews = "showNews"
    static let showMerchInfo = "showMerchInfo"
    static let lightMode = "lightMode"
    static let conferenceCode = "conferenceCode"
    static let speakerAISummaries = "speakerAISummaries"
    static let showPastEvents = "showPastEvents"
    static let showHidden = "showHidden"
    static let showCustomEvents = "showCustomEvents"
    static let showConflictAlert = "showConflictAlert"
    static let launchScreen = "launchScreen"
    static let filterMatchModeSpeakers = "filterMatchModeSpeakers"
    static let filterMatchModeMerch = "filterMatchModeMerch"
    static let easterEggPeriod = "easterEggPeriod"
    static let easterEggMaxOpacity = "easterEggMaxOpacity"
    static let lastMapIndex = "lastMapIndex"
    static let infoLogoCollapsedCodes = "infoLogoCollapsedCodes"
}
