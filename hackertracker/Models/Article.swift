//
//  Article.swift
//  hackertracker
//
//  Created by Seth W Law on 6/8/22.
//

import FirebaseFirestore
import Foundation

struct Article: Codable, Identifiable {
    @DocumentID var docId: String?
    var id: Int
    var name: String
    var text: String
    var updatedAt: Date

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case text
        case updatedAt = "updated_at"
    }
}

struct NewsItem: Codable {
    var id: Int
}
