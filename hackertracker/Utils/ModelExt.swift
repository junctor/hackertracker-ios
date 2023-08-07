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

    func filters(typeIds: Set<Int>, bookmarks: [Int32], tagTypes: [TagType]) -> Self {
        if typeIds.isEmpty {
            return self
        } else {
            var filterTypes: [Int: [Int]] = [:]
            for typeId in typeIds {
                if let tagType = tagTypes.first(where: { $0.tags.contains(where: { $0.id == typeId }) }) {
                    if filterTypes.keys.contains(tagType.id) {
                        filterTypes[tagType.id]?.append(typeId)
                    } else {
                        filterTypes[tagType.id] = [typeId]
                    }
                }
            }
            
            if typeIds.contains(1337) {
                return self.filter { isFiltered(tagIds: $0.tagIds, filterTypes: filterTypes) &&
                                     bookmarks.contains(Int32($0.id))
                }
            } else {
                return self.filter { isFiltered(tagIds: $0.tagIds, filterTypes: filterTypes) }
            }
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

func isFiltered(tagIds: [Int], filterTypes: [Int: [Int]]) -> Bool {
    var results: [Bool] = []
    for ft in filterTypes {
        var my_r = false
        if ft.value.contains(where: {tagIds.contains($0)}) {
            my_r = true
        }
        results.append(my_r)
    }
    if results.contains(false) {
        return false
    } else {
        return true
    }
}
