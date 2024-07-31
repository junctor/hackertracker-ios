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
    @State var notExists: Bool = false
    @AppStorage("notifyAt") var notifyAt: Int = 20
    let dfu = DateFormatterUtility.shared
    @State var showAddContentModal = false
    @EnvironmentObject var viewModel: InfoViewModel

    var body: some View {
        Menu {
            ShareContentView(content: content, session: session)
            Button {
                showAddContentModal.toggle()
            } label: {
                Label("Export to Calendar", systemImage: "calendar")
            }
            Button {
                // showingAlert = true
                if notExists {
                    NotificationUtility.removeNotification(id: session.id)
                    NSLog("removing alert for \(content.title) - \(session.id)")
                    notExists = false
                } else {
                    let notDate = session.beginTimestamp.addingTimeInterval(Double((-notifyAt)) * 60)
                    NotificationUtility.scheduleNotification(date: notDate, id: session.id, title: content.title, location: viewModel.locations.first(where: {$0.id == session.locationId})?.name ?? "unknown")
                    NSLog("adding alert for \(content.title) - \(session.id)")
                    notExists = true
                }
                NSLog("Clicked Alert")
            } label: {
                    Label(notExists ? "Remove Alert" : "Add Alert", systemImage: notExists ? "bell.fill" : "bell")
            }
            
        } label: {
            Image(systemName: "chevron.down.square")
        }
        .onAppear {
            notExists = NotificationUtility.notificationExists(id: session.id)
        }
        .sheet(isPresented: $showAddContentModal) {
            AddContent(content: content, session: session)
        }
    }
    
}
