//
//  Location.swift
//  hackertracker
//
//  Created by Seth W Law on 6/8/22.
//

import FirebaseFirestore
import FirebaseFirestoreSwift
import Foundation

struct Location: Codable {
    var id: Int
    var conferenceName: String?
    var name: String
    var hotel: String
}
