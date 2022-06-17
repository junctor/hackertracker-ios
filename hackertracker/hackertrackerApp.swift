//
//  hackertrackerApp.swift
//  hackertracker
//
//  Created by Seth W Law on 5/2/22.
//

import CoreData
import Firebase
import SwiftUI

@main
struct hackertrackerApp: App {
    let persistenceController = PersistenceController.shared
    
    // Setup for bookmarks object that will be passed around.
    @StateObject var bookmarks: oBookmarks = oBookmarks()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(bookmarks)
        }
    }
}
