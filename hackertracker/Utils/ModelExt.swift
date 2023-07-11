//
//  ModelUtils.swift
//  hackertracker
//
//  Created by Caleb Kinney on 6/2/23.
//

import Foundation

extension Date {
    func dayOfDate() -> Date? {
        let calendar = Calendar.current

        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: self)

        components.hour = 0
        components.minute = 0
        components.second = 0
        components.timeZone = DateFormatterUtility.shared.timeZone

        return calendar.date(from: components)
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
