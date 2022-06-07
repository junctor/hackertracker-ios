//
//  Event.swift
//  hackertracker
//
//  Created by Seth W Law on 6/6/22.
//

import Foundation
import FirebaseFirestoreSwift

struct Event: Codable {
    var id: Int
    var conferenceName: String
    var description: String
    var begin: Date
    var end: Date
    var includes: String
    var links: String
    var title: String
    var location: String
    var speakers: [Speaker]
}
