//
//  Event.swift
//  hackertracker
//
//  Created by Seth W Law on 6/6/22.
//

import FirebaseFirestore
import Foundation

struct Event: Codable, Identifiable {
    var id: Int
    var contentId: Int
    var description: String
    var beginTimestamp: Date
    var endTimestamp: Date
    var title: String
    var locationId: Int
    var people: [Person]
    var tagIds: [Int]
    var relatedIds: [Int]?
    /// Non-nil when this Event was synthesized from a locally-stored
    /// CustomEvent. Lets cells render the row with its own accent
    /// color and lets the schedule pipeline distinguish user-created
    /// rows from Firestore-decoded ones. NOT part of CodingKeys, so
    /// Firestore-decoded Events leave this nil automatically.
    var customEventID: UUID? = nil
    /// Custom-event row stripe color, copied from CustomEvent.colorHex
    /// by the synthesizer. Same NOT-in-CodingKeys treatment so Firestore
    /// events stay nil and the cell helpers fall through to the existing
    /// tag-color lookup.
    var customColorHex: String? = nil
    /// Minimum age required to see this event, copied from the parent
    /// Content by the synthesizer. NOT in CodingKeys (events are built in
    /// code); nil = no minimum.
    var visibleAgeMin: Int? = nil

    private enum CodingKeys: String, CodingKey {
        case id
        case contentId
        case description
        case beginTimestamp = "begin_timestamp"
        case endTimestamp = "end_timestamp"
        case title
        case locationId
        case people
        case tagIds = "tag_ids"
    }
}

struct Person: Codable, Identifiable {
    var id: Int
    var sortOrder: Int
    var tagId: Int?
    
    private enum CodingKeys: String, CodingKey {
        case id = "person_id"
        case sortOrder = "sort_order"
        case tagId = "tag_id"
    }
}

struct EventSpeaker: Codable, Identifiable {
    var id: Int
    var name: String
    var title: String?
}

struct EventLocation: Codable, Identifiable {
    var id: Int
    var name: String
}

extension Event {
    /// Synthesize an Event from a locally-stored CustomEvent for the
    /// supplied conference code. Returns nil when the custom event
    /// doesn't target this conference, or when required fields are
    /// missing (Core Data optional storage).
    ///
    /// `conferenceCodes` on the source: empty array means "any
    /// conference" (a personal event that should appear on every
    /// schedule the user opens); non-empty means "only these
    /// conferences".
    static func from(custom: CustomEvent, conferenceCode: String) -> Event? {
        guard let id = custom.id,
              let title = custom.title,
              let begin = custom.beginTimestamp,
              let end = custom.endTimestamp else { return nil }
        let codes = (custom.conferenceCodes as? [String]) ?? []
        if !codes.isEmpty && !codes.contains(conferenceCode) { return nil }
        return Event(
            id: CustomEventUtility.notificationID(for: custom),
            contentId: 0,
            description: custom.eventDescription ?? "",
            beginTimestamp: begin,
            endTimestamp: end,
            title: title,
            locationId: 0,
            people: [],
            tagIds: [],
            relatedIds: nil,
            customEventID: id,
            customColorHex: custom.colorHex
        )
    }
}
