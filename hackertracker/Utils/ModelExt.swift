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

    func filters(typeIds: Set<Int>) -> Self {
        if typeIds.isEmpty {
            return self
        } else {
            return self.filter { typeIds.contains($0.type.id) }
        }
    }

    func search(text: String) -> Self {
        if text.isEmpty {
            return self
        } else {
            let lowerText = text.lowercased()
            return self.filter { $0.title.lowercased().contains(lowerText) }
        }
    }

    func eventDayGroup() -> [Date: [Event]] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:00.000-0000"

        let eventDict = Dictionary(grouping: self, by: {
            dateFormatter.date(from: $0.begin)?.dayOfDate() ?? Date()
        })
        return eventDict
    }

    func eventDateTimeGroup() -> [Date: [Event]] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:00.000-0000"

        let eventDict = Dictionary(grouping: self, by: {
            dateFormatter.date(from: $0.begin) ?? Date()
        })
        return eventDict
    }
}
