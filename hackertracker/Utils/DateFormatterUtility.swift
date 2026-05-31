//
//  DateFormatterUtility.swift
//  hackertracker
//
//  Created by Seth W Law on 6/7/22.
//

import Foundation

// Phase 3c: @MainActor isolation. The previous singleton + mutable
// `timeZone` ivar pattern is not Sendable in Swift 6 mode. All access
// happens from SwiftUI views (already MainActor) or AddEventController's
// MainActor Task, so isolating the whole class to MainActor is the
// minimal, behavior-preserving fix.
@MainActor
class DateFormatterUtility {
    // Phase 4: starts at device-current. ClockService.apply switches to the
    // active conference's timezone once Firestore delivers the Conference.
    var timeZone: TimeZone? = .current

    static let shared = DateFormatterUtility(tz: .current)

    init(tz: TimeZone?) {
        if let zone = tz {
            update(tz: zone)
        } else {
            if let zone = timeZone {
                update(tz: zone)
            } else {
                Log.app.error("DateFormatterUtility: set timezone failed")
            }
        }
    }

    func update(tz: TimeZone?) {
        Log.app.info("DateFormatterUtility: tz -> \(tz?.identifier ?? "<nil>", privacy: .public)")
        timeZone = tz

        yearMonthDayTimeFormatter.timeZone = timeZone
        timezoneFormatter.timeZone = timeZone
        yearMonthDayFormatter.timeZone = timeZone
        monthDayTimeFormatter.timeZone = timeZone
        monthDayFormatter.timeZone = timeZone
        iso8601Formatter.timeZone = timeZone
        iso8601ColonFormatter.timeZone = timeZone
        yearMonthDayNoTimeZoneTimeFormatter.timeZone = timeZone
        dayOfWeekFormatter.timeZone = timeZone
        shortDayOfMonthFormatter.timeZone = timeZone
        dayMonthDayOfWeekFormatter.timeZone = timeZone
        shortDayMonthDayTimeOfWeekFormatter.timeZone = timeZone
        shortDayMonthDay12HourOfWeekFormatter.timeZone = timeZone
        dayOfWeekTimeFormatter.timeZone = timeZone
        hourMinuteTimeFormatter.timeZone = timeZone
        hourMinute12TimeFormatter.timeZone = timeZone
        monthDayYearFormatter.timeZone = timeZone
        locationTimeFormatter.timeZone = timeZone
        // Phase 4: include longMonthDayFormatter ("August 11"-style label) in
        // the sweep; previously its TZ never tracked the active conference.
        longMonthDayFormatter.timeZone = timeZone
    }

    func preferLocalTime() -> Bool {
        UserDefaults.standard.bool(forKey: "showLocaltime")
    }

    // time format
    let yearMonthDayTimeFormatter = { () -> DateFormatter in
        let formatter = DateFormatter()
        // Phase 4: timezone set by ClockService.apply on conference load.
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss z"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    // Current Timezone
    let timezoneFormatter = { () -> DateFormatter in
        let formatter = DateFormatter()
        formatter.dateFormat = "z"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    // Year-Month-Day
    let yearMonthDayFormatter = { () -> DateFormatter in
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    // Month/Day/Year
    let monthDayYearFormatter = { () -> DateFormatter in
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    // Aug 11
    let monthDayFormatter = { () -> DateFormatter in
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    // August 11
    let longMonthDayFormatter = { () -> DateFormatter in
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    // UTC time format
    let monthDayTimeFormatter = { () -> DateFormatter in
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    // UTC iso8601 time format
    let iso8601Formatter = { () -> DateFormatter in
        let formatter = DateFormatter()
        // Phase 4: timezone set by ClockService.apply on conference load.
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.sZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    // UTC iso8601 time format with colon
    let iso8601ColonFormatter = { () -> DateFormatter in
        let formatter = DateFormatter()
        // Phase 4: timezone set by ClockService.apply on conference load.
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssxxx"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    // Year-Month-Day time format
    let yearMonthDayNoTimeZoneTimeFormatter = { () -> DateFormatter in
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    // DOW format
    let dayOfWeekFormatter = { () -> DateFormatter in
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEEE"
        return formatter
    }()

    // D format
    let shortDayOfMonthFormatter = { () -> DateFormatter in
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "E"
        return formatter
    }()

    // DOW format
    let dayMonthDayOfWeekFormatter = { () -> DateFormatter in
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EE, MMM d"
        return formatter
    }()

    // DOW format
    let shortDayMonthDayTimeOfWeekFormatter = { () -> DateFormatter in
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EE, MMM d HH:mm"
        return formatter
    }()
    
    // DOW format
    let shortDayMonthDay12HourOfWeekFormatter = { () -> DateFormatter in
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EE, MMM d h:mm a"
        return formatter
    }()

    // DOW Hour:Minute time format
    let dayOfWeekTimeFormatter = { () -> DateFormatter in
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EE HH:mm"
        return formatter
    }()

    // Hour:Minute time format
    let hourMinuteTimeFormatter = { () -> DateFormatter in
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    // Hour:Minute AM/PM time format
    let hourMinute12TimeFormatter = { () -> DateFormatter in
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    // UTC location time format
    let locationTimeFormatter = { () -> DateFormatter in
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    func getConferenceDates(start: Date, end: Date) -> [String] {
        let calendar = NSCalendar.current
        var ret: [String] = []

        let components = calendar.dateComponents([.day], from: start, to: end)
        ret.append(yearMonthDayFormatter.string(from: start))
        var cur = start
        if components.day ?? 1 > 1 {
            for _ in 1 ... (components.day ?? 1) {
                cur = calendar.date(byAdding: Calendar.Component.day, value: 1, to: cur) ?? Date()
                ret.append(yearMonthDayFormatter.string(from: cur))
            }
        }
        return ret
    }
}

