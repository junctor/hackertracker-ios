//
//  TrackingPermission.swift
//  hackertracker
//
//  Phase 5d: App Tracking Transparency (ATT) prompt for Firebase Analytics.
//
//  The app links both FirebaseAnalytics and FirebaseAnalyticsWithoutAdIdSupport
//  (a known Firebase quirk where the regular variant wins when both are linked
//  in the same target). To stay honest with Apple's privacy policy, we now
//  explicitly ask for tracking permission on first launch and only let
//  Analytics collect IDFA when the user says yes.
//
//  Crashlytics is unaffected — it does NOT use IDFA and does NOT require ATT.
//

import Foundation
import AppTrackingTransparency
import AdSupport
import FirebaseAnalytics

@MainActor
enum TrackingPermission {
    /// Ask once per app install. Subsequent launches read the cached status
    /// and either honor "authorized" (Analytics gets IDFA) or honor any other
    /// status (Analytics has no IDFA but still collects aggregate metrics).
    ///
    /// Calling this multiple times is safe: ATTrackingManager only shows the
    /// system prompt on the first call; later calls return the cached status
    /// without re-prompting.
    static func requestIfNeeded() async {
        // iOS 14+ guarantees ATTrackingManager but we already require iOS 17,
        // so no #available gate is needed.
        let current = ATTrackingManager.trackingAuthorizationStatus
        Log.app.debug("ATT status before request: \(current.rawValue, privacy: .public)")

        let result: ATTrackingManager.AuthorizationStatus
        if current == .notDetermined {
            result = await ATTrackingManager.requestTrackingAuthorization()
            Log.app.info("ATT status after request: \(result.rawValue, privacy: .public)")
        } else {
            result = current
        }

        // Tell Firebase whether to consume ad/IDFA data.
        // .authorized   -> full ad/analytics consent
        // anything else -> denied; Analytics keeps aggregate metrics only.
        let granted = (result == .authorized)
        Analytics.setConsent([
            .analyticsStorage: .granted,                         // aggregate metrics always
            .adStorage: granted ? .granted : .denied,            // IDFA / ad-targeting
            .adUserData: granted ? .granted : .denied,
            .adPersonalization: granted ? .granted : .denied,
        ])
        Log.app.info("Firebase Analytics consent updated. adStorage granted=\(granted, privacy: .public)")
    }
}
