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
        print("Adding Feedback for content \(id)")

        do {
            try context.save()
        } catch {
            let nsError = error as NSError
            print("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }

    static func getFeedbacks(context: NSManagedObjectContext) -> [Int] {
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Feedbacks")
        do {
            if let res = try context.fetch(fr) as? [Feedback] {
                print("FeedbackUtility.getFeedbacks: \(res.count) feedback returned")
                return res.map { $0.id }
            } else {
                print("FeedbackUtility.getFeedbacks: no feedback returned")
                return []
            }
        } catch {
            let nsError = error as NSError
            print("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return []
    }
}
