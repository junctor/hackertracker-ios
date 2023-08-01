//
//  ModelUtils.swift
//  hackertracker
//
//  Created by Caleb Kinney on 6/2/23.
//

import Foundation

extension Date {
    func dayOfDate() -> Date? {
        var calendar = Calendar.current
        if let tz = DateFormatterUtility.shared.timeZone {
            calendar.timeZone = tz
        }
        return calendar.startOfDay(for: self)
    }
}

extension [TagType] {
    func tags(category: String) -> [Tag] {
        var retArray: [Tag] = []
        for tagtype in self.filter({$0.category == category}) {
            retArray.append(contentsOf: tagtype.tags)
        }
        return retArray
    }
}

extension [Event] {
    func types() -> [Int: EventType] {
        return self.reduce(into: [:]) { tags, event in
            tags[event.type.id] = event.type
        }
    }

    func filters(typeIds: Set<Int>, bookmarks: [Int32]) -> Self {
        if typeIds.isEmpty {
            return self
        } else {
            return self.filter { $0.tagIds.filter({ typeIds.contains($0) }).count > 0 || (typeIds.contains(1337) && bookmarks.contains(Int32($0.id))) }
        }
    }

    func eventDayGroup() -> [Date: [Event]] {
        let eventDict = Dictionary(grouping: self, by: {
            $0.beginTimestamp.dayOfDate() ?? Date()
        })
        return eventDict
    }

    func eventDateTimeGroup() -> [Date: [Event]] {
        let eventDict = Dictionary(grouping: self, by: {
            $0.beginTimestamp.dayOfDate() ?? Date()
        })
        return eventDict
    }
}
