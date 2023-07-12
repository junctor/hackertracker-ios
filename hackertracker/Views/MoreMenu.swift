//
//  MoreMenu.swift
//
//  Created by Caleb Kinney on 5/17/23.
//

import SwiftUI
import EventKit
import EventKitUI

struct MoreMenu: View {
    let event: Event
    let dfu = DateFormatterUtility.shared
    @State var showAddEventModal = false
    @Binding var showingAlert: Bool

    var body: some View {
        Menu {
            ShareView(event: event, title: true)
            Button {
                showAddEventModal.toggle()
            } label: {
                Label("Save to Calendar", systemImage: "calendar")
            }
            Button {
                showingAlert = true
            } label: {
                Label("Add Notification", systemImage: NotificationUtility.notificationExists(event: event) ? "bell.fill" : "bell")
            }
            
        } label: {
            Image(systemName: "ellipsis")
        }
        .sheet(isPresented: $showAddEventModal) {
            AddEvent(event: event)
        }
    }
    
    func addEvent(htEvent: Event) {
        // Create an event store
        let store = EKEventStore()

        // Create an event
        let event = EKEvent(eventStore: store)
        event.title = htEvent.title
        event.startDate = htEvent.beginTimestamp
        event.endDate = htEvent.endTimestamp
        event.timeZone = dfu.timeZone
        event.location = htEvent.location.name
        event.notes = htEvent.description
    }
}
