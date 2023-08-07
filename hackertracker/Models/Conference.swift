//
//  Conference.swift
//  hackertracker
//
//  Created by Seth W Law on 6/6/22.
//

import FirebaseFirestore
import FirebaseFirestoreSwift
import Foundation

struct Conference: Codable, Identifiable, Equatable {
    static func == (lhs: Conference, rhs: Conference) -> Bool {
        lhs.code == rhs.code
    }
    
    @DocumentID var id: String?
    var name: String
    var description: String
    var code: String
    var endDate: String
    var startDate: String
    var timezone: String?
    var coc: String?
    var kickoffTimestamp: Date
    var startTimestamp: Date
    var endTimestamp: Date
    var maps: [Map]?
    var documents: [Document]?
    var hidden: Bool
    var enableMerch: Bool
    var enableMerchCart: Bool
    var homeMenuId: Int
    var tagline: String?
    var merchHelpDocId: Int?

    private enum CodingKeys: String, CodingKey {
        case name
        case description
        case code
        case endDate = "end_date"
        case startDate = "start_date"
        case timezone
        case coc = "codeofconduct"
        case kickoffTimestamp = "kickoff_timestamp"
        case startTimestamp = "start_timestamp"
        case endTimestamp = "end_timestamp"
        case maps
        case documents
        case hidden
        case enableMerch = "enable_merch"
        case enableMerchCart = "enable_merch_cart"
        case homeMenuId = "home_menu_id"
        case tagline = "tagline_text"
        case merchHelpDocId = "merch_help_doc_id"
    }
}
