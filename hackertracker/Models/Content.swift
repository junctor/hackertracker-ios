//
//  Event.swift
//  hackertracker
//
//  Created by Seth W Law on 6/6/22.
//

import FirebaseFirestore
import FirebaseFirestoreSwift
import Foundation

struct Content: Codable, Identifiable {
    @DocumentID var docID: String?
    var id: Int
    var conferenceName: String?
    var description: String
    var links: [Link]
    var logo: Logo?
    var media: [Media]
    var people: [Person]
    var sessions: [Session]
    var tagIds: [Int]
    var title: String

    private enum CodingKeys: String, CodingKey {
        case id
        case conferenceName
        case description
        case links
        case logo
        case media
        case people
        case sessions
        case tagIds = "tag_ids"
        case title
    }
}

struct Session: Codable, Identifiable {
    var id: Int
    var beginTimestamp: Date
    var channelId: Int?
    var endTimestamp: Date
    var locationId: Int
    var recordingPolicyId: Int
    var timezoneName: String

    private enum CodingKeys: String, CodingKey {
        case id = "session_id"
        case beginTimestamp = "begin_timestamp"
        case channelId = "channel_id"
        case endTimestamp = "end_timestamp"
        case locationId = "location_id"
        case recordingPolicyId = "recordingpolicy_id"
        case timezoneName = "timezone_name"
    }
}
