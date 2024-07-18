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
    let dfu = DateFormatterUtility.shared
    @State var showAddContentModal = false
    @State var showingAlert: Bool = false
    @State var notExists: Bool = false
    @AppStorage("notifyAt") var notifyAt: Int = 20
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
                showingAlert = true
                NSLog("Clicked Alert")
            } label: {
                    Label(notExists ? "Remove Alert" : "Add Alert", systemImage: notExists ? "bell.fill" : "bell")
            }
            
        } label: {
            Image(systemName: "ellipsis")
        }
        .onAppear {
            notExists = notificationExists(id: session.id)
        }
        .sheet(isPresented: $showAddContentModal) {
            AddContent(content: content, session: session)
        }
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text(notExists ? "Remove" : "Add"),
                message: Text(notExists ? "Remove alert for \(content.title)" : "Add alert \(notifyAt) minutes before start of \(content.title)"),
                primaryButton: Alert.Button.default(Text("Yes")) {
                    if notExists {
                        NotificationUtility.removeNotification(id: session.id)
                        notExists = false
                    } else {
                        let notDate = session.beginTimestamp.addingTimeInterval(Double((-notifyAt)) * 60)
                        NotificationUtility.scheduleNotification(date: notDate, id: session.id, title: content.title, location: viewModel.locations.first(where: {$0.id == session.locationId})?.name ?? "unknown")
                        notExists = true
                    }
                },
                secondaryButton: .cancel(Text("No"))
            )
        }
    }
    
    func notificationExists(id: Int) -> Bool {
        var ret : Bool = false
        UNUserNotificationCenter.current().getPendingNotificationRequests(completionHandler: { notificationRequests in
            for nr in notificationRequests where nr.identifier == "hackertracker-\(id)" {
                ret = true
                break
            }
        })
        return ret
    }
}
