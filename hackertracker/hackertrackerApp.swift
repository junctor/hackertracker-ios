//
//  hackertrackerApp.swift
//  hackertracker
//
//  Created by Seth W Law on 5/2/22.
//

import SwiftUI
import Firebase

@main
struct hackertrackerApp: App {
    let persistenceController = PersistenceController.shared
    
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup<ContentView> {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext) as! ContentView
        }
    }
}
