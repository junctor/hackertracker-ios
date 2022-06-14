//
//  BookmarkUtility.swift
//  hackertracker
//
//  Created by Seth W Law on 6/14/22.
//

import Foundation
import CoreData
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
        let fr: NSFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Bookmarks")
        fr.predicate = NSPredicate(format: "id = %d", id)
        do {
            let res = try context.fetch(fr) as! [NSManagedObject]
            print("Deleting \(res.count) Bookmarks")
            for r in res {
                context.delete(r)
            }
            try context.save()
        } catch {
            let nsError = error as NSError
            print("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
/*

private func deleteBookmark(offsets: IndexSet) {
    withAnimation {
        offsets.map { bookmarks[$0] }.forEach(viewContext.delete)

        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}*/
}
