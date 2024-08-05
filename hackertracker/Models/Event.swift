//
//  Event.swift
//  hackertracker
//
//  Created by Seth W Law on 6/6/22.
//

import FirebaseFirestore
import Foundation

struct Event: Codable, Identifiable {
    var id: Int
    var contentId: Int
    var description: String
    var beginTimestamp: Date
    var endTimestamp: Date
    var title: String
    var locationId: Int
    var people: [Person]
    var tagIds: [Int]

    private enum CodingKeys: String, CodingKey {
        case id
        case contentId
        case description
        case beginTimestamp = "begin_timestamp"
        case endTimestamp = "end_timestamp"
        case title
        case locationId
        case people
        case tagIds = "tag_ids"
    }
}

struct Person: Codable, Identifiable {
    var id: Int
    var sortOrder: Int
    var tagId: Int?
    
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
