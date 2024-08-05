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
        print("Adding ReadNews for content \(id)")

        do {
            try context.save()
        } catch {
            let nsError = error as NSError
            print("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }

    static func getReadNews(context: NSManagedObjectContext) -> [Int] {
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "News")
        do {
            if let res = try context.fetch(fr) as? [NewsItem] {
                print("NewsUtility.getReadNews: \(res.count) news items returned")
                return res.map { $0.id }
            } else {
                print("NewsUtility.getReadNews: no read news items returned")
                return []
            }
        } catch {
            let nsError = error as NSError
            print("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return []
    }
}
