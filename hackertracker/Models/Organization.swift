//
//  Organization.swift
//  hackertracker
//
//  Created by Seth W Law on 6/9/23.
//

import FirebaseFirestore
import FirebaseFirestoreSwift
import Foundation

struct Organization: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    var description: String
    var logo: Logo?
    var links: [Link]
    var media: [Media]
    var tag_ids: [Int]
    var tag_id_as_organizer: Int?

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case logo
        case links
        case media
        case tag_ids
        case tag_id_as_organizer
    }
}

struct Link: Codable {
    var label: String
    var url: String
    var type: String
    
    private enum CodingKeys: String, CodingKey {
        case label
        case url
        case type
    }
}

struct Logo: Codable {
    // var checksum_sha256: String
    var url: String?
}
