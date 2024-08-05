//
//  Menu.swift
//  hackertracker
//
//  Created by Seth Law on 7/31/23.
//

import FirebaseFirestore
import Foundation

struct InfoMenu: Codable, Identifiable {
    var id: Int
    var title: String
    var items: [MenuItem]
    
    private enum CodingKeys: String, CodingKey {
        case id
        case title = "title_text"
        case items
    }
}

struct MenuItem: Codable, Identifiable {
    var id: Int
    var function: String
    var prohibitTagFilter: String
    var sortOrder: Int
    var title: String
    var appliedTagIds: [Int]
    var documentId: Int?
    var menuId: Int?
    var symbol: String?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case function
        case prohibitTagFilter = "prohibit_tag_filter"
        case sortOrder = "sort_order"
        case title = "title_text"
        case appliedTagIds = "applied_tag_ids"
        case documentId = "document_id"
        case menuId = "menu_id"
        case symbol = "apple_sfsymbol"
    }
}
