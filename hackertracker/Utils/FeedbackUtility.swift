//
//  FeedbackUtility.swift
//  hackertracker
//
//  Created by Seth Law on 7/30/24.
//

import CoreData
import Foundation
import SwiftUI

class FeedbackUtility {
    static func addFeedback(context: NSManagedObjectContext, id: Int) {
        let newItem = Feedbacks(context: context)
        newItem.id = Int32(id)
        Log.app.debug("adding feedback for content \(id)")

        do {
            try context.save()
        } catch {
            let nsError = error as NSError
            Log.app.error("feedback save failed: \(nsError, privacy: .public)")
            CrashReport.record(nsError, context: ["op": "addFeedback"])
        }
    }

    static func getFeedbacks(context: NSManagedObjectContext) -> [Int] {
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Feedbacks")
        do {
            if let res = try context.fetch(fr) as? [Feedback] {
                Log.app.debug("getFeedbacks: \(res.count) items")
                return res.map { $0.id }
            } else {
                Log.app.debug("getFeedbacks: empty")
                return []
            }
        } catch {
            let nsError = error as NSError
            Log.app.error("feedback fetch failed: \(nsError, privacy: .public)")
            CrashReport.record(nsError, context: ["op": "getFeedbacks"])
        }
        return []
    }
}
