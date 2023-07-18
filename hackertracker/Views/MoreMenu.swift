//
//  MoreMenu.swift
//
//  Created by Caleb Kinney on 5/17/23.
//

import SwiftUI
#if canImport(EventKit)
import EventKit
import EventKitUI
#endif

struct MoreMenu: View {
    let event: Event
    let dfu = DateFormatterUtility.shared
    @State var showAddEventModal = false
    @Binding var showingAlert: Bool
    @Binding var notExists: Bool

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
                Label(notExists ? "Remove Alert" : "Add Alert", systemImage: notExists ? "bell.fill" : "bell")
            }
            
        } label: {
            Image(systemName: "ellipsis")
        }
        .sheet(isPresented: $showAddEventModal) {
            AddEvent(event: event)
        }
    }
    
}
