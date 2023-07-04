//
//  BookmarkUtility.swift
//  hackertracker
//
//  Created by Seth W Law on 6/14/22.
//

import CoreData
import Foundation
import SwiftUI

class BookmarkUtility {
    static func addBookmark(context: NSManagedObjectContext, id: Int) {
        let newItem = Bookmarks(context: context)
        newItem.id = Int32(id)
        print("Adding Bookmark for event \(id)")

        do {
            try context.save()
        } catch {
            let nsError = error as NSError
            print("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }

    static func deleteBookmark(context: NSManagedObjectContext, id: Int) {
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Bookmarks")
        fr.predicate = NSPredicate(format: "id = %d", id)
        do {
            if let res = try context.fetch(fr) as? [NSManagedObject] {
                print("Deleting \(res.count) Bookmarks")
                for r in res {
                    context.delete(r)
                }
            }
            try context.save()
        } catch {
            let nsError = error as NSError
            print("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }

    static func getBookmarks(context: NSManagedObjectContext) -> [Int] {
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Bookmarks")
        do {
            if let res = try context.fetch(fr) as? [Bookmark] {
                print("BookmarkUtility.getBookmarks: \(res.count) bookmarks returned")
                return res.map { $0.id }
            } else {
                print("BookmarkUtility.getBookmarks: no bookmarks returned")
                return []
            }
        } catch {
            let nsError = error as NSError
            print("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return []
    }
}
