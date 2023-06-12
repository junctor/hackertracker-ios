//
//  Conference.swift
//  hackertracker
//
//  Created by Seth W Law on 6/6/22.
//

import FirebaseFirestore
import FirebaseFirestoreSwift
import Foundation

struct Conference: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    var code: String
    var endDate: String
    var startDate: String
    var timeZone: String?
    var coc: String?
    var startTimestamp: Date
    var endTimestamp: Date
    var maps: [Map]
    var documents: [Document]?
    var hidden: Bool

    private enum CodingKeys: String, CodingKey {
        case name
        case code
        case endDate = "end_date"
        case startDate = "start_date"
        case timeZone = "tz"
        case coc = "codeofconduct"
        case startTimestamp = "start_timestamp"
        case endTimestamp = "end_timestamp"
        case maps
        case documents
        case hidden
    }
}
