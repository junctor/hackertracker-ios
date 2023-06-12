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
    var tag_ids: [Int]

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case logo
        case links
        case tag_ids
    }
}

struct Link: Codable {
    var label: String
    var type: String
    var url: String
}

struct Logo: Codable {
    // var checksum_sha256: String
    var url: String?
}
