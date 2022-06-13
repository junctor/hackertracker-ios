//
//  Article.swift
//  hackertracker
//
//  Created by Seth W Law on 6/8/22.
//

import FirebaseFirestore
import FirebaseFirestoreSwift
import Foundation

struct Article: Codable {
    @DocumentID var id: String?
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
