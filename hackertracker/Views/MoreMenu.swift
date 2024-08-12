//
//  MoreMenu.swift
//
//  Created by Caleb Kinney on 5/17/23.
//

import SwiftUI
import EventKit
import EventKitUI

struct MoreContentMenu: View {
    let content: Content
    let session: Session
    // @Binding var showingAlert: Bool
    @Binding var notExists: Bool
    
    let dfu = DateFormatterUtility.shared
    @State var showAddContentModal = false

    var body: some View {
        Menu {
            ShareContentView(content: content, session: session)
            Button {
                showAddContentModal.toggle()
            } label: {
                Label("Export to Calendar", systemImage: "calendar")
            }
            NotificationButton(content: content, session: session, notExists: $notExists)
        } label: {
            Image(systemName: "chevron.down.square")
        }
        .fullScreenCover(isPresented: $showAddContentModal) {
            AddContent(content: content, session: session)
        }
    }
    
}

struct NotificationButton: View {
    var content: Content
    var session: Session
    @Binding var notExists: Bool
    @AppStorage("notifyAt") var notifyAt: Int = 20
    @EnvironmentObject var viewModel: InfoViewModel
    
    var body: some View {
        Button {
            if notExists {
                NotificationUtility.removeNotification(id: session.id)
                notExists = false
            } else {
                let notDate = session.beginTimestamp.addingTimeInterval(Double((-notifyAt)) * 60)
                NotificationUtility.scheduleNotification(date: notDate, id: session.id, title: content.title, location: viewModel.locations.first(where: {$0.id == session.locationId})?.name ?? "unknown")
                notExists = true
            }
        } label: {
                Label(notExists ? "Remove Alert" : "Add Alert", systemImage: notExists ? "bell.fill" : "bell")
        }
    }
}
