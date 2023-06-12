//
//  Document.swift
//  hackertracker
//
//  Created by Seth W Law on 6/8/22.
//

import FirebaseFirestore
import FirebaseFirestoreSwift
import Foundation

struct Document: Codable, Identifiable {
    @DocumentID var docID: String?
    var id: Int
    var title: String
    var body: String

    private enum CodingKeys: String, CodingKey {
        case id
        case title = "title_text"
        case body = "body_text"
    }
}
