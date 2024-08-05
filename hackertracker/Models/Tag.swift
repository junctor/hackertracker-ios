//
//  Tag.swift
//  hackertracker
//
//  Created by Seth W Law on 6/10/23.
//

import FirebaseFirestore
import Foundation

struct TagType: Codable, Identifiable {
    var id: Int
    var category: String
    var isBrowsable: Bool
    var isSingleValued: Bool
    var label: String
    var sortOrder: Int
    var tags: [Tag]

    private enum CodingKeys: String, CodingKey {
        case id
        case category
        case isBrowsable = "is_browsable"
        case isSingleValued = "is_single_valued"
        case label
        case sortOrder = "sort_order"
        case tags
    }
}

struct Tag: Codable, Identifiable {
    var id: Int
    var label: String
    var sortOrder: Int
    var description: String
    var colorBackground: String?
    var colorForeground: String?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case label
        case sortOrder = "sort_order"
        case description
        case colorBackground = "color_background"
        case colorForeground = "color_foreground"
    }
}
