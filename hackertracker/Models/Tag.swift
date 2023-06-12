//
//  Tag.swift
//  hackertracker
//
//  Created by Seth W Law on 6/10/23.
//

import FirebaseFirestore
import FirebaseFirestoreSwift
import Foundation

struct TagType: Codable {
    @DocumentID var id: String?
    var category: String
    var is_browsable: Bool
    var is_single_valued: Bool
    var label: String
    var sort_order: Int
    var tags: [Tag]

    private enum CodingKeys: String, CodingKey {
        case id
        case category
        case is_browsable
        case is_single_valued
        case label
        case sort_order
        case tags
    }
}

struct Tag: Codable {
    var id: Int
    var label: String
    var sort_order: Int
    var description: String
    var color_background: String
    var color_foreground: String
}
