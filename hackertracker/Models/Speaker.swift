//
//  Speaker.swift
//  hackertracker
//
//  Created by Seth W Law on 6/6/22.
//

import FirebaseFirestore
import Foundation

struct Speaker: Codable, Equatable {
    @DocumentID var docId: String?
    var id: Int
    var conferenceName: String
    var description: String
    var link: String
    var links: [SpeakerLink]
    var media: [Media]?
    var name: String
    var affiliations: [SpeakerAffiliation]?
    var pronouns: String?
    var title: String?
    var twitter: String
    var eventIds: [Int]

    static func == (lhs: Speaker, rhs: Speaker) -> Bool {
        if lhs.id == rhs.id, lhs.name == rhs.name, lhs.description == rhs.description {
            return true
        } else {
            return false
        }
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case conferenceName = "conference"
        case description
        case link
        case links
        case media
        case name
        case affiliations
        case pronouns
        case title
        case twitter
        case eventIds = "event_ids"
    }
}

struct SpeakerAffiliation: Codable {
    var organization: String
    var title: String
    
    private enum CodingKeys: String, CodingKey {
        case organization
        case title
    }
}

struct SpeakerLink: Codable {
    var title: String
    var url: String
    var sortOrder: Int
    
    private enum CodingKeys: String, CodingKey {
        case title
        case url
        case sortOrder = "sort_order"
    }
}

struct SpeakerEvent: Codable, Identifiable {
    var id: Int
    var title: String?
}
