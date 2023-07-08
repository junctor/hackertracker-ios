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
        let newItem = Cart(context: context)
        newItem.variantId = Int32(variantId)
        newItem.count = Int32(count)
        print("Creating Cart item for variant \(variantId) - \(count)")
        
        do {
            try context.save()
        } catch {
            let nsError = error as NSError
            print("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
    static func updateItem(context: NSManagedObjectContext, variantId: Int, count: Int) {
        let fr = NSFetchRequest<Cart>(entityName: "Cart")
        fr.predicate = NSPredicate(format: "variantId = %d", variantId)
        do {
            let res = try context.fetch(fr)
            if res.count > 0 {
                var item = res[0]
                print("Updating \(item.variantId) Cart Item to \(count)")
                item.count = Int32(count)
            }            
            try context.save()
        } catch {
            let nsError = error as NSError
            print("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
    static func deleteItem(context: NSManagedObjectContext, variantId: Int) {
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Cart")
        fr.predicate = NSPredicate(format: "variantId = %d", variantId)
        do {
            if let res = try context.fetch(fr) as? [NSManagedObject] {
                print("Deleting \(res.count) cart items")
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
    
    static func emptyCart(context: NSManagedObjectContext) {
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Cart")
        do {
            if let res = try context.fetch(fr) as? [NSManagedObject] {
                print("Deleting \(res.count) cart items")
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
    
    static func getCart(context: NSManagedObjectContext) -> [Int: Int] {
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Cart")
        do {
            if let res = try context.fetch(fr) as? [Cart] {
                print("CartUtility.getCart: \(res.count) cart items returned")
                return res.reduce(into: [Int: Int]()) {
                    $0[Int($1.variantId)] = Int($1.count)
                }
            } else {
                print("CartUtility.getCart: no cart items returned")
                return [:]
            }
        } catch {
            let nsError = error as NSError
            print("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return [:]
    }
}
