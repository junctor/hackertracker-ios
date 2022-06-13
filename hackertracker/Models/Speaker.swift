//
//  Speaker.swift
//  hackertracker
//
//  Created by Seth W Law on 6/6/22.
//

import FirebaseFirestore
import FirebaseFirestoreSwift
import Foundation

struct Speaker: Codable, Equatable {
    @DocumentID var id: String?
    var conferenceName: String
    var description: String
    var link: String
    var name: String
    var title: String
    var twitter: String
    var events: [Event]

    static func == (lhs: Speaker, rhs: Speaker) -> Bool {
        if lhs.id == rhs.id, lhs.name == rhs.name, lhs.description == rhs.description {
            return true
        } else {
            return false
        }
    }
}
