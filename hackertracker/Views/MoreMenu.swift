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

    var body: some View {
        Menu {
            ShareView(event: event, title: true)
            Button {
                showAddEventModal.toggle()
            } label: {
                Label("Save to Calendar", systemImage: "calendar")
            }
            Button {} label: {
                Label("Alert", systemImage: "bell")
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

        // Create a view controller
        /* let eventEditViewController = EKEventEditViewController()
        eventEditViewController.event = event
        eventEditViewController.eventStore = store
        eventEditViewController.editViewDelegate = self

        // Present the view controller
        present(eventEditViewController, animated: true) */
    }
}
