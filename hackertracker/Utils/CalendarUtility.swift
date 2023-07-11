//
//  CalendarUtility.swift
//  hackertracker
//
//  Created by Seth Law on 7/10/23.
//

import EventKit
import Combine
import Foundation
import SwiftUI

struct CalendarUtility {
    let eventStore = EKEventStore()

    let status: EKAuthorizationStatus = EKEventStore.authorizationStatus(for: EKEntityType.event)

    func requestAuthorization() {
        eventStore.requestAccess(to: .event) { _, error in
            if let error = error {
                print("Request authorization error: \(error.localizedDescription)")
            }
        }
    }

    func requestAuthorizationAndSave(event: Event) {
        eventStore.requestAccess(to: EKEntityType.event) { authorized, error in
            if authorized {
                DispatchQueue.main.async {
                    self.createEvent(htEvent: event)
                }
            }
            if let error = error {
                print("Request authorization error: \(error.localizedDescription)")
            }
        }
    }

    func addEvent(event: Event) {
        switch status {
        case .notDetermined:
            requestAuthorizationAndSave(event: event)
        case .authorized:
            createEvent(htEvent: event)
        case .restricted, .denied:
            print("Denied")
            //deniedAccessAlert()
        @unknown default:
            break
        }
    }

    private func createEvent(htEvent: Event) -> EKEvent {
        let event = EKEvent(eventStore: eventStore)
        var notes = htEvent.description
        let speakers = htEvent.speakers.map { $0.name }
        if !speakers.isEmpty {
            if speakers.count > 1 {
                notes = "Speakers: \(speakers.joined(separator: ", "))\n\n\(htEvent.description)"
            } else {
                notes = "Speaker: \(speakers.first ?? "")\n\n\(htEvent.description)"
            }
        }

        event.calendar = eventStore.defaultCalendarForNewEvents
        event.startDate = htEvent.beginTimestamp
        event.endDate = htEvent.endTimestamp
        event.title = htEvent.title
        event.location = htEvent.location.name
        event.notes = notes

        if !htEvent.links.isEmpty {
            if htEvent.links.contains(where: { $0.url.contains("https://forum.defcon.org") }) {
                if let link = htEvent.links.first(where: { $0.url.contains("https://forum.defcon.org") }), let url = URL(string: link.url) {
                    event.url = url
                }
            } else {
                if let link = htEvent.links.first, let url = URL(string: link.url) {
                    event.url = url
                }
            }
        }

        return event
    }

    private func isDuplicate(newEvent: EKEvent) -> Bool {
        let predicate = eventStore
            .predicateForEvents(withStart: newEvent.startDate, end: newEvent.endDate, calendars: nil)
        let currentEvents = eventStore.events(matching: predicate)
        let duplicateEvent = currentEvents
            .contains(where: { $0.title == newEvent.title
                    && $0.startDate == newEvent.startDate
                    && $0.endDate == newEvent.endDate
            })
        return duplicateEvent
    }
}
