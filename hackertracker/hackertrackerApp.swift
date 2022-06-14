//
//  hackertrackerApp.swift
//  hackertracker
//
//  Created by Seth W Law on 5/2/22.
//

import SwiftUI
import Firebase
import CoreData

@main
struct hackertrackerApp: App {
    let persistenceController = PersistenceController.shared
    @FetchRequest(entity: Settings.entity(), sortDescriptors: [])
        private var settings: FetchedResults<Settings>
    
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
