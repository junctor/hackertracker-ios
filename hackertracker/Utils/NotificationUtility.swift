//
//  NotificationUtility.swift
//  hackertracker
//
//  Created by Seth Law on 7/12/23.
//

import Foundation
// Swift 6 strict concurrency: UNNotificationRequest isn't yet annotated
// Sendable in UserNotifications. Treat the framework's Sendable
// diagnostics as warnings so the existing call sites (notably the
// addNotification closure capture below) keep compiling clean.
@preconcurrency import UserNotifications

enum NotificationUtility {
    /// Phase 1 fix: previously a DispatchSemaphore-blocking accessor that could deadlock
    /// under priority inversion when called from the main thread. Now async.
    static var status: UNAuthorizationStatus {
        get async {
            await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
        }
    }

    static func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, error in
            if let error = error {
                Log.notifications.error("requestAuthorization error: \(error.localizedDescription, privacy: .public)")
                CrashReport.record(error, context: ["op": "requestAuthorization"])
            }
        }
    }

    static func addNotification(request: UNNotificationRequest) {
        UNUserNotificationCenter.current().getNotificationSettings { setttings in
            switch setttings.authorizationStatus {
            case .authorized, .provisional:
                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        Log.notifications.error("add request failed: \(error.localizedDescription, privacy: .public)")
                        CrashReport.record(error, context: ["op": "addNotificationRequest"])
                    }
                }
            case .notDetermined:
                NotificationUtility.requestAuthorization()
            case .denied:
                break
            case .ephemeral:
                break
            @unknown default:
                break
            }
        }
    }

    static func checkAndRequestAuthorization() {
        Task {
            let status = await NotificationUtility.status
            switch status {
            case .notDetermined:
                requestAuthorization()
            default:
                break
            }
        }
    }
    
    /* static func scheduleNotification(date: Date, event: Event) {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents(in: .current, from: date)
        let newComponents = DateComponents(calendar: calendar, timeZone: .current, month: components.month, day: components.day, hour: components.hour, minute: components.minute)

        let trigger = UNCalendarNotificationTrigger(dateMatching: newComponents, repeats: false)

        let content = UNMutableNotificationContent()
        content.title = "Upcoming Event"
        content.body = "\(event.title) in \(String(describing: event.location.name))"
        content.sound = UNNotificationSound.default

        let request = UNNotificationRequest(identifier: "hackertracker-\(event.id)", content: content, trigger: trigger)

        NotificationUtility.addNotification(request: request)
    } */
    
    static func scheduleNotification(date: Date, id: Int, title: String, location: String) {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents(in: .current, from: date)
        let newComponents = DateComponents(calendar: calendar, timeZone: .current, month: components.month, day: components.day, hour: components.hour, minute: components.minute)

        let trigger = UNCalendarNotificationTrigger(dateMatching: newComponents, repeats: false)

        let content = UNMutableNotificationContent()
        content.title = "Upcoming Event"
        content.body = "\(title) in \(location)"
        content.sound = UNNotificationSound.default

        let request = UNNotificationRequest(identifier: "hackertracker-\(id)", content: content, trigger: trigger)

        NotificationUtility.addNotification(request: request)
    }

    static func removeNotification(event: Event) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["hackertracker-\(event.id)"])
    }
    
    static func removeNotification(id: Int) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["hackertracker-\(id)"])
    }
    
    /// Phase 1 fix: previous implementation returned true whenever ANY pending
    /// notification existed, so bookmark notifications never refreshed correctly.
    /// Now matches the specific identifier.
    static func notificationExists(id: Int) async -> Bool {
        let target = "hackertracker-\(id)"
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        return requests.contains(where: { $0.identifier == target })
    }
    
    /* static func updateNotificationForEvent(date: Date, event: Event) {
        self.removeNotification(event: event)
        self.scheduleNotification(date: date, event: event)
    } */
    
    static func removeAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
