//
//  NewsUtility.swift
//  hackertracker
//
//  Created by Seth Law on 8/2/24.
//

import Foundation
import CoreData
import SwiftUI

class NewsUtility {
    static func addReadNews(context: NSManagedObjectContext, id: Int) {
        let newItem = News(context: context)
        newItem.id = Int32(id)
        Log.app.debug("adding read news \(id)")

        do {
            try context.save()
        } catch {
            let nsError = error as NSError
            Log.app.error("readNews save failed: \(nsError, privacy: .public)")
            CrashReport.record(nsError, context: ["op": "addReadNews"])
        }
    }

    static func getReadNews(context: NSManagedObjectContext) -> [Int] {
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "News")
        do {
            if let res = try context.fetch(fr) as? [NewsItem] {
                Log.app.debug("getReadNews: \(res.count) items")
                return res.map { $0.id }
            } else {
                Log.app.debug("getReadNews: empty")
                return []
            }
        } catch {
            let nsError = error as NSError
            Log.app.error("readNews fetch failed: \(nsError, privacy: .public)")
            CrashReport.record(nsError, context: ["op": "getReadNews"])
        }
        return []
    }
}
