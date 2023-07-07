//
//  Event.swift
//  hackertracker
//
//  Created by Seth W Law on 6/6/22.
//

import FirebaseFirestore
import FirebaseFirestoreSwift
import Foundation

struct Event: Codable, Identifiable {
    @DocumentID var docID: String?
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
    var location: EventLocation
    var speakers: [EventSpeaker]
    var people: [Person]
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
        case people
        case type
    }
}

struct Person: Codable, Identifiable {
    var id: Int
    var sortOrder: Int
    var tagId: Int
    
    private enum CodingKeys: String, CodingKey {
        case id = "person_id"
        case sortOrder = "sort_order"
        case tagId = "tag_id"
    }
}

struct EventSpeaker: Codable, Identifiable {
    var id: Int
    var name: String
    var title: String?
}

struct EventLocation: Codable, Identifiable {
    var id: Int
    var name: String
}

struct Links: Codable {
    var label: String
    var url: String
}
