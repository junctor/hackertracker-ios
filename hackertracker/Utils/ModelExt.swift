//
//  ModelExt.swift
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
        for tagtype in filter({ $0.category == category }) {
            retArray.append(contentsOf: tagtype.tags)
        }
        return retArray
    }
}

extension [Content] {
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
                return filter {
                    isFiltered(tagIds: $0.tagIds, filterTypes: filterTypes)
                    && bookmarks.contains(Int32($0.id))
                }
            } else {
                return filter { isFiltered(tagIds: $0.tagIds, filterTypes: filterTypes) }
            }
        }
    }
    
    func isFiltered(tagIds: [Int], filterTypes: [Int: [Int]]) -> Bool {
        var results: [Bool] = []
        for ft in filterTypes {
            var myR = false
            if ft.value.contains(where: { tagIds.contains($0) }) {
                myR = true
            }
            results.append(myR)
        }
        if results.contains(false) {
            return false
        } else {
            return true
        }
    }
}

extension [Event] {
    func types() -> [Int: EventType] {
        return reduce(into: [:]) { tags, event in
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
                return filter {
                    isFiltered(tagIds: $0.tagIds, filterTypes: filterTypes)
                    && bookmarks.contains(Int32($0.id))
                }
            } else {
                return filter { isFiltered(tagIds: $0.tagIds, filterTypes: filterTypes) }
            }
        }
    }
    
    func eventDayGroup(showLocaltime: Bool, conference: Conference?) -> [(key: String, value: [Event])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        formatter.timeZone =
        showLocaltime
        ? TimeZone.current : TimeZone(identifier: conference?.timezone ?? "America/Los_Angeles")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        let eventDict = Dictionary(
            grouping: self,
            by: {
                formatter.string(from: $0.beginTimestamp)
            }
        )
        return eventDict.sorted {
            ($0.value.first?.beginTimestamp ?? Date()) < ($1.value.first?.beginTimestamp ?? Date())
        }
    }
    
    func isFiltered(tagIds: [Int], filterTypes: [Int: [Int]]) -> Bool {
        var results: [Bool] = []
        for ft in filterTypes {
            var myR = false
            if ft.value.contains(where: { tagIds.contains($0) }) {
                myR = true
            }
            results.append(myR)
        }
        if results.contains(false) {
            return false
        } else {
            return true
        }
    }
}
