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

        return calendar.date(from: components)
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
            return self.filter { typeIds.contains($0.type.id) || (typeIds.contains(1337) && bookmarks.contains(Int32($0.id))) }
        }
    }

    func eventDayGroup() -> [Date: [Event]] {
        let dfu = DateFormatterUtility.shared

        let eventDict = Dictionary(grouping: self, by: {
            dfu.iso8601Formatter.date(from: $0.begin)?.dayOfDate() ?? Date()
        })
        return eventDict
    }

    func eventDateTimeGroup() -> [Date: [Event]] {
        let dfu = DateFormatterUtility.shared

        let eventDict = Dictionary(grouping: self, by: {
            dfu.iso8601Formatter.date(from: $0.begin) ?? Date()
        })
        return eventDict
    }
}
