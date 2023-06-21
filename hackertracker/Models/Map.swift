//
//  Map.swift
//  hackertracker
//
//  Created by Seth W Law on 6/6/22.
//

import FirebaseFirestore
import FirebaseFirestoreSwift
import Foundation

struct Map: Codable, Identifiable {
    @DocumentID var docID: String?
    var id: Int
    var url: String
    var description: String
    
    private enum CodingKeys: String, CodingKey {
        case id
        case url
        case description
    }
}
