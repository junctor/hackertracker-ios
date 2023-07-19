//
//  FAQ.swift
//  hackertracker
//
//  Created by Seth W Law on 6/8/22.
//

import FirebaseFirestore
import FirebaseFirestoreSwift
import Foundation

struct FAQ: Codable, Identifiable {
    @DocumentID var id: String?
    var question: String
    var answer: String

    private enum CodingKeys: String, CodingKey {
        case id
        case question
        case answer
    }
}
