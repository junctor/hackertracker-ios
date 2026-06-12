//
//  Logger+HT.swift
//  hackertracker
//
//  Centralized os.Logger subsystems and a Crashlytics bridge.
//  Replace `print(...)` with the matching `Log.<category>.<level>(...)`.
//

import Foundation
import os

#if canImport(FirebaseCrashlytics)
import FirebaseCrashlytics
#endif

/// Namespaced os.Logger instances. Keep categories small and stable so Console.app
/// filters and Crashlytics breadcrumbs stay readable.
enum Log {
    static let subsystem = Bundle.main.bundleIdentifier ?? "org.beezle.hackertracker"

    static let app           = Logger(subsystem: subsystem, category: "app")
    static let firestore     = Logger(subsystem: subsystem, category: "firestore")
    static let coreData      = Logger(subsystem: subsystem, category: "coredata")
    static let notifications = Logger(subsystem: subsystem, category: "notifications")
    static let bookmarks     = Logger(subsystem: subsystem, category: "bookmarks")
    static let cart          = Logger(subsystem: subsystem, category: "cart")
    static let ui            = Logger(subsystem: subsystem, category: "ui")
    static let network       = Logger(subsystem: subsystem, category: "network")
}

/// Lightweight Crashlytics bridge that compiles even if the SDK isn't linked yet.
/// Once Crashlytics is added via SwiftPM (FirebaseCrashlytics product on the app target),
/// these calls become real reports automatically.
enum CrashReport {
    /// Records a non-fatal error with optional context. Safe to call from any thread.
    static func record(_ error: Error, context: [String: Any] = [:], file: String = #fileID, line: Int = #line) {
        Log.app.error("non-fatal: \(String(describing: error), privacy: .public) at \(file, privacy: .public):\(line)")
        #if canImport(FirebaseCrashlytics)
        if !context.isEmpty {
            Crashlytics.crashlytics().setCustomKeysAndValues(context)
        }
        Crashlytics.crashlytics().record(error: error)
        #endif
    }

    /// Adds a breadcrumb-style log line visible in the next Crashlytics report.
    static func breadcrumb(_ message: String) {
        Log.app.info("\(message, privacy: .public)")
        #if canImport(FirebaseCrashlytics)
        Crashlytics.crashlytics().log(message)
        #endif
    }

    /// Attach a stable user identifier (e.g. anonymized FCM token or conference code).
    static func setUserContext(conferenceCode: String?) {
        #if canImport(FirebaseCrashlytics)
        if let code = conferenceCode {
            Crashlytics.crashlytics().setCustomValue(code, forKey: "conference_code")
        }
        #endif
        _ = conferenceCode
    }
}
