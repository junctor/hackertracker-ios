//
//  Location.swift
//  hackertracker
//
//  Created by Seth W Law on 6/8/22.
//

import FirebaseFirestore
import FirebaseFirestoreSwift
import Foundation

struct Location: Codable, Identifiable {
    @DocumentID var docId: String?
    var id: Int
    var name: String
    var hotel: String
    var defaultStatus: String?
    var schedule: [Schedule]
    var hierExtentLeft: Int
    var hierExtentRight: Int
    var hierDepth: Int
    var parentId: Int
    var peerSortOrder: Int
    var shortName: String
    
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case hotel
        case defaultStatus = "default_status"
        case hierDepth = "hier_depth"
        case hierExtentLeft = "hier_extent_left"
        case hierExtentRight = "hier_extent_right"
        case schedule
        case parentId = "parent_id"
        case peerSortOrder = "peer_sort_order"
        case shortName = "short_name"
    }
}

struct Schedule: Codable {
    var begin: Date
    var end: Date
    var notes: String
    var status: String
}
