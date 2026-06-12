//
//  CartUtility.swift
//  hackertracker
//
//  Created by Seth Law on 7/8/23.
//

import Foundation
import CoreData

class CartUtility {
    static func addItem(context: NSManagedObjectContext, variantId: Int, count: Int) {
        let curCount = itemExists(context: context, variantId: variantId)
        if curCount > 0 {
            return updateItem(context: context, variantId: variantId, count: curCount + count)
        }
        let newItem = Cart(context: context)
        newItem.variantId = Int32(variantId)
        newItem.count = Int32(count)
        Log.cart.debug("create item variant=\(variantId, privacy: .public) count=\(count)")
        
        do {
            try context.save()
        } catch {
            let nsError = error as NSError
            Log.cart.error("addItem failed: \(nsError, privacy: .public)")
            CrashReport.record(nsError, context: ["op": "addItem"])
        }
    }
    
    static func itemExists(context: NSManagedObjectContext, variantId: Int) -> Int {
        let fr = NSFetchRequest<Cart>(entityName: "Cart")
        fr.predicate = NSPredicate(format: "variantId = %d", variantId)
        do {
            let res = try context.fetch(fr)
            if res.count > 0 {
                return Int(res[0].count)
            }
        } catch {
            let nsError = error as NSError
            Log.cart.error("saveContext failed: \(nsError, privacy: .public)")
            CrashReport.record(nsError, context: ["op": "saveContext"])
        }
        return 0
    }
    
    static func updateItem(context: NSManagedObjectContext, variantId: Int, count: Int) {
        let fr = NSFetchRequest<Cart>(entityName: "Cart")
        fr.predicate = NSPredicate(format: "variantId = %d", variantId)
        do {
            let res = try context.fetch(fr)
            if res.count > 0 {
                let item = res[0]
                Log.cart.debug("update item variant=\(item.variantId, privacy: .public) count=\(count)")
                item.count = Int32(count)
            }            
            try context.save()
        } catch {
            let nsError = error as NSError
            Log.cart.error("updateItem failed: \(nsError, privacy: .public)")
            CrashReport.record(nsError, context: ["op": "updateItem"])
        }
    }
    
    static func deleteItem(context: NSManagedObjectContext, variantId: Int) {
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Cart")
        fr.predicate = NSPredicate(format: "variantId = %d", variantId)
        do {
            if let res = try context.fetch(fr) as? [NSManagedObject] {
                Log.cart.debug("deleting \(res.count) cart items")
                for r in res {
                    context.delete(r)
                }
            }
            try context.save()
        } catch {
            let nsError = error as NSError
            Log.cart.error("deleteItems(product) failed: \(nsError, privacy: .public)")
            CrashReport.record(nsError, context: ["op": "deleteItemsForProduct"])
        }
    }
    
    static func emptyCart(context: NSManagedObjectContext) {
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Cart")
        do {
            if let res = try context.fetch(fr) as? [NSManagedObject] {
                Log.cart.debug("deleting \(res.count) cart items")
                for r in res {
                    context.delete(r)
                }
            }
            try context.save()
        } catch {
            let nsError = error as NSError
            Log.cart.error("deleteAllItems failed: \(nsError, privacy: .public)")
            CrashReport.record(nsError, context: ["op": "deleteAllItems"])
        }
    }
    
    static func getCart(context: NSManagedObjectContext) -> [Int: Int] {
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Cart")
        do {
            if let res = try context.fetch(fr) as? [Cart] {
                Log.cart.debug("getCart: \(res.count) items")
                return res.reduce(into: [Int: Int]()) {
                    $0[Int($1.variantId)] = Int($1.count)
                }
            } else {
                Log.cart.debug("getCart: empty")
                return [:]
            }
        } catch {
            let nsError = error as NSError
            Log.cart.error("getCart failed: \(nsError, privacy: .public)")
            CrashReport.record(nsError, context: ["op": "getCart"])
        }
        return [:]
    }
}
