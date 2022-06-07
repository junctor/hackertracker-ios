//
//  Conference.swift
//  hackertracker
//
//  Created by Seth W Law on 6/6/22.
//

import Foundation
import FirebaseFirestoreSwift

struct Conference: Codable {
    var id: Int
    var name: String
    var code: String
    var endDate: String
    var startDate: String
    var timeZone: String
    var coc: String
    var startTimestamp: Date
    var endTimestamp: Date
    var maps: [Map]
    var hidden: Bool
}
