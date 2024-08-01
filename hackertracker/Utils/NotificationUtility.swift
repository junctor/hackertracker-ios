//
//  NotificationUtility.swift
//  hackertracker
//
//  Created by Seth Law on 7/12/23.
//

import Foundation
import UserNotifications

enum NotificationUtility {
    static var status: UNAuthorizationStatus? {
        var authorizationStatus: UNAuthorizationStatus?
        let semasphore = DispatchSemaphore(value: 0)

        DispatchQueue.global().async {
            UNUserNotificationCenter.current().getNotificationSettings { setttings in
                authorizationStatus = setttings.authorizationStatus
                semasphore.signal()
            }
        }

        semasphore.wait()

        return authorizationStatus
    }

    static func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, error in
            if let error = error {
                print("Request authorization error: \(error.localizedDescription)")
            }
        }
    }

    static func addNotification(request: UNNotificationRequest) {
        UNUserNotificationCenter.current().getNotificationSettings { setttings in
            switch setttings.authorizationStatus {
            case .authorized, .provisional:
                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        NSLog("Error: \(error)")
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
        guard let status = NotificationUtility.status else { return }
        switch status {
        case .notDetermined:
            requestAuthorization()
        default:
            break
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
    
    static func notificationExists(id: Int) async -> Bool {
        var ret : Bool = false
        let notificationRequests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        ret = notificationRequests.map({"hackertracker-\($0.identifier)"}).count > 0
        return ret
    }
    
    /* static func updateNotificationForEvent(date: Date, event: Event) {
        self.removeNotification(event: event)
        self.scheduleNotification(date: date, event: event)
    } */
    
    static func removeAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
