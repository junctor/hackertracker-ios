//
//  hackertrackerApp.swift
//  hackertracker
//
//  Created by Seth W Law on 5/2/22.
//

import SwiftUI

@main
struct hackertrackerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
