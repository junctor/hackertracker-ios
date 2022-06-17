//
//  EventRow.swift
//  hackertracker
//
//  Created by Seth W Law on 6/7/22.
//

import CoreData
import SwiftUI

struct EventRow: View {
    @Environment(\.managedObjectContext) private var viewContext

    var event: Event
    @EnvironmentObject var bookmarks: oBookmarks
    let dfu = DateFormatterUtility.shared

    var body: some View {
        HStack {
            Rectangle().fill(event.type.swiftuiColor).frame(width: 10)
            VStack(alignment: .leading, spacing: 0, content: {
                Text(dfu.shortDayOfMonthFormatter.string(from: event.beginTimestamp))
                    .font(.caption)
                Text(dfu.hourMinuteTimeFormatter.string(from: event.beginTimestamp))
                    .font(.body)
                Text(dfu.timezoneFormatter.string(from: event.beginTimestamp))
                    .font(.caption)

            })
            .padding()

            VStack(alignment: .leading, spacing: 0, content: {
                Text(event.title)
                    .font(.title3)
                if event.speakers.count > 0 {
                    Text(self.speakersString(speakers: event.speakers))
                        .font(.body)
                }

                Text(event.location.name)
                    .font(.caption)
            })
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(0)

            HStack(alignment: .top, spacing: 0, content: {
                VStack(alignment: .center, spacing: 5, content: {
                    if bookmarks.bookmarks.contains(event.id) {
                        Image(systemName: "star.fill")
                            .onTapGesture {
                                BookmarkUtility.deleteBookmark(context: viewContext, id: event.id)
                                if let index = bookmarks.bookmarks.firstIndex(of: event.id) {
                                    bookmarks.bookmarks.remove(at: index)
                                }
                            }
                    } else {
                        Image(systemName: "star")
                            .onTapGesture {
                                BookmarkUtility.addBookmark(context: viewContext, id: event.id)
                                bookmarks.bookmarks.append(event.id)
                            }
                    }
                })
            })
        }
    }

    func speakersString(speakers: [EventSpeaker]) -> String {
        var ret = ""
        speakers.forEach { s in
            if ret != "" {
                ret += ", "
            }
            ret += s.name
        }
        return ret
    }
}

struct EventRow_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ScheduleView()
        }
    }
}
