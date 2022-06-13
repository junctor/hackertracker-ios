//
//  Settings.swift
//  hackertracker
//
//  Created by Seth W Law on 6/6/22.
//

import Foundation
import CoreData

class OldSettings: NSManagedObject, Identifiable {
    @NSManaged public var conference: String?
    @NSManaged private var dark: NSNumber?
    @NSManaged private var hidden: NSNumber?
    
    public var isDark: Bool? {
        get { return Bool(exactly: dark ?? true) }
        set { dark = NSNumber(booleanLiteral: newValue ?? true) }
    }
    
    public var showHidden: Bool? {
        get { return Bool(exactly: hidden ?? false) }
        set { hidden = NSNumber(booleanLiteral: newValue ?? false) }
    }
}

extension OldSettings {
    static func getSettings() -> NSFetchRequest<Settings>{
        let request: NSFetchRequest<Settings> = Settings.fetchRequest() as! NSFetchRequest<Settings>
        
        request.sortDescriptors = [NSSortDescriptor(key: "conference", ascending: true)]
        return request
    }
}
