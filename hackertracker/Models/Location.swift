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
    var defaultStatus: String
    var schedule: [Schedule]
    var hierExtentLeft: Int
    var hierExtentRight: Int
    var hierDepth: Int
    var parentId: Int
    var peerSortOrder: Int
    var shortName: String
    
    /* init?(dictionary: [String: Any]) {
        self.id = dictionary["id"] as? Int ?? 0
        self.name = dictionary["name"] as? String ?? ""
        self.hotel = dictionary["hotel"] as? String ?? ""
        self.defaultStatus = dictionary["default_status"] as? String ?? ""
        self.schedule = []
        if let scheduleValues = dictionary["schedule"] as? [Any] {
            if scheduleValues.count > 0 {
                schedule = scheduleValues.compactMap { element -> Schedule? in
                    if let element = element as? [String: Any], let sched = Schedule(dictionary: element) {
                        return sched
                    }
                    return nil
                }
            }
        }
        self.hierExtentLeft = dictionary["hier_extent_left"] as? Int ?? 0
        self.hierExtentRight = dictionary["hier_extent_right"] as? Int ?? 0
        self.hierDepth = dictionary["hier_depth"] as? Int ?? 0
        self.parentId = dictionary["parent_id"] as? Int ?? 0
        self.peerSortOrder = dictionary["peer_sort_order"] as? Int ?? 0
        self.shortName = dictionary["short_name"] as? String ?? ""
        /* self.init(id: id, conferenceId: conferenceId, conferenceName: conferenceName, name: name, hotel: hotel,
                  defaultStatus: defaultStatus, schedule: schedule, hierExtentLeft: hierExtentLeft,
                  hierExtentRight: hierExtentRight, hierDepth: hierDepth, parentId: parentId,
                  peerSortOrder: peerSortOrder, shortName: shortName) */
    } */
    
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
    
    init?(dictionary: [String: Any]) {
        let dfu = DateFormatterUtility.shared
        let tmpDate = "2019-01-01T00:00:00.000-0000"
        self.begin = dfu.locationTimeFormatter.date(from: dictionary["begin"] as? String ?? tmpDate) ?? Date()
        if let beginTimestamp = dictionary["begin"] as? Timestamp {
            self.begin = beginTimestamp.dateValue()
        }
        self.end = dfu.locationTimeFormatter.date(from: dictionary["end"] as? String ?? tmpDate) ?? Date()
        if let endTimestamp = dictionary["end"] as? Timestamp {
            self.end = endTimestamp.dateValue()
        }
        self.status = dictionary["status"] as? String ?? ""
        self.notes = dictionary["notes"] as? String ?? ""

        // self.init(begin: begin, end: end, notes: notes, status: status)
    }
}
