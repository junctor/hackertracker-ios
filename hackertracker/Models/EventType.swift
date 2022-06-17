//
//  EventType.swift
//  hackertracker
//
//  Created by Seth W Law on 6/8/22.
//

import FirebaseFirestore
import FirebaseFirestoreSwift
import Foundation
import SwiftUI

struct EventType: Codable, Equatable {
    var id: Int
    var color: String
    var conferenceName: String?
    var name: String

    static func == (lhs: EventType, rhs: EventType) -> Bool {
        if lhs.id == rhs.id, lhs.name == rhs.name {
            return true
        } else {
            return false
        }
    }
}

extension EventType {
    var swiftuiColor: Color {
        Color(
            UIColor(hex: color) ?? .purple)
    }
}
