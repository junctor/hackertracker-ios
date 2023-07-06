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
    @DocumentID var docId: String?
    var id: Int
    var conferenceName: String
    var description: String
    var link: String
    var links: [SpeakerLink]
    var media: [SpeakerMedia]?
    var name: String
    var pronouns: String?
    var title: String?
    var twitter: String
    var events: [SpeakerEvent]

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
        case pronouns
        case title
        case twitter
        case events
    }
}

struct SpeakerMedia: Codable {
    var assetId: Int
    var filetype: String
    var md5: String
    var name: String
    var sortOrder: Int
    var url: String
    
    private enum CodingKeys: String, CodingKey {
        case assetId = "asset_id"
        case filetype
        case md5 = "hash_md5"
        case name
        case sortOrder = "sort_order"
        case url
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
