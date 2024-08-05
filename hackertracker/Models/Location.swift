//
//  Location.swift
//  hackertracker
//
//  Created by Seth W Law on 6/8/22.
//

import FirebaseFirestore
import Foundation

struct Location: Codable, Identifiable {
    var id: Int
    var name: String
    var hotel: String
    var defaultStatus: String
    var schedule: [ScheduleTime]
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
        case schedule
        case hierExtentLeft = "hier_extent_left"
        case hierExtentRight = "hier_extent_right"
        case hierDepth = "hier_depth"
        case parentId = "parent_id"
        case peerSortOrder = "peer_sort_order"
        case shortName = "short_name"
    }
}

struct ScheduleTime: Codable {
    var begin: String
    var end: String
    var status: String
    
    private enum CodingKeys: String, CodingKey {
        case begin
        case end
        case status
    }
}
