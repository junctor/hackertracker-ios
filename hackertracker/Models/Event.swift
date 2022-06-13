//
//  Event.swift
//  hackertracker
//
//  Created by Seth W Law on 6/6/22.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct Event: Codable {
    var id: Int
    var conferenceName: String?
    var description: String
    var begin: String
    var beginTimestamp: Date
    var endTimestamp: Date
    var end: String
    var includes: String
    var links: [Links]
    var title: String
    var location: Location
    var speakers: [Speaker]
    var type: EventType

    private enum CodingKeys: String, CodingKey {
        case id
        case conferenceName
        case description
        case begin
        case beginTimestamp = "begin_timestamp"
        case endTimestamp = "end_timestamp"
        case end
        case includes
        case links
        case title
        case location
        case speakers
        case type
    }
}

struct Links: Codable {
    var label: String
    var url: String
}
