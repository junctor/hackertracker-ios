//
//  Vendor.swift
//  hackertracker
//
//  Created by Seth W Law on 6/8/22.
//

import FirebaseFirestore
import Foundation

struct Vendor: Codable {
    @DocumentID var id: String?
    var name: String
    var desc: String
    var link: String
    var updatedAt: Date

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case desc
        case link
        case updatedAt = "updated_at"
    }
}
