//
//  Persistence.swift
//  hackertracker
//
//  Created by Seth W Law on 5/2/22.
//

import CoreData
import os

struct PersistenceController {
    static let shared = PersistenceController()

    // Phase 3c (Swift 6): preview is a SwiftUI-preview-only singleton; isolation isn't needed.
    nonisolated(unsafe) static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for _ in 0 ..< 10 {
            let newItem = Bookmarks(context: viewContext)
        }
        do {
            try viewContext.save()
        } catch {
            // Preview context only — log instead of crashing so SwiftUI previews keep rendering.
            Log.coreData.error("preview save failed: \(String(describing: error), privacy: .public)")
        }
        return result
    }()

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "hackertracker")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { storeDescription, error in
            if let error = error as NSError? {
                // Phase 0: report instead of crash. Phase 1 will add a recovery path
                // (wipe local store + prompt user) for the recoverable subset of errors.
                Log.coreData.error(
                    "loadPersistentStores failed for \(storeDescription.url?.absoluteString ?? "<nil>", privacy: .public): \(error, privacy: .public)"
                )
                CrashReport.record(error, context: [
                    "store": storeDescription.url?.absoluteString ?? "<nil>",
                    "phase": "loadPersistentStores"
                ])
            } else {
                Log.coreData.info("persistent store loaded: \(storeDescription.url?.lastPathComponent ?? "<nil>", privacy: .public)")
            }
        })
        // Phase 1 fix: prevent silent save failures when CloudKit imports of Bookmarks/Cart
        // race with local writes. Property-object trump policy biases toward the in-memory
        // user action, which matches the UX intent for these models.
        // Swift 6: prefer the NSMergePolicy initializer over the Objective-C global
        // constant (which is exposed as a non-Sendable `var`).
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.shouldDeleteInaccessibleFaults = true
    }
}
