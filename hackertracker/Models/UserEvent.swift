//
//  UserEvent.swift
//  hackertracker
//
//  Created by Seth W Law on 6/9/22.
//

import FirebaseFirestore
import FirebaseFirestoreSwift
import Foundation

struct UserEvent: Codable, Equatable {
    var event: Event
    var bookmark: Bookmark

    static func == (lhs: UserEvent, rhs: UserEvent) -> Bool {
        if lhs.event.id == rhs.event.id,
           lhs.event.title == rhs.event.title,
           lhs.event.description == rhs.event.description
        {
            return true
        } else {
            return false
        }
    }
}
