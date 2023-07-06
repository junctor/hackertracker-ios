//
//  EventRowView.swift
//
//  Created by Caleb Kinney on 4/8/23.
//

import SwiftUI

struct EventCell: View {
    let event: Event
    let bookmarks: [Int32]
    @Environment(\.managedObjectContext) private var viewContext
    let dfu = DateFormatterUtility.shared

    func bookmarkAction() {
        if bookmarks.contains(Int32(event.id)) {
            print("EventCellView: Removing Bookmark \(event.id)")
            BookmarkUtility.deleteBookmark(context: viewContext, id: event.id)
        } else {
            print("EventCellView: Adding Bookmark \(event.id)")
            BookmarkUtility.addBookmark(context: viewContext, id: event.id)
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .center) {
                Rectangle().fill(event.type.swiftuiColor)
                    .frame(width: 6)
                VStack {
                    Text(dfu.hourMinuteTimeFormatter.string(from: event.beginTimestamp))
                        .font(.subheadline)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(event.title).font(.headline)
                    if !event.speakers.isEmpty {
                        Text(event.speakers.map { $0.name }.joined(separator: ", ")).font(.subheadline)
                    }
                    Text(event.location.name).font(.caption2)
                    VStack(alignment: .leading) {
                        HStack {
                            Circle().foregroundColor(event.type.swiftuiColor)
                                .frame(width: 8, height: 8, alignment: .center)
                            Text(event.type.name).font(.caption)
                            Spacer()
                        }
                    }.frame(minWidth: 0, maxWidth: .infinity)
                }

                HStack(alignment: .center) {
                    Button {
                        bookmarkAction()
                    } label: {
                        Image(systemName: bookmarks.contains(Int32(event.id)) ? "bookmark.fill" : "bookmark")
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }

        }.swipeActions {
            Button(bookmarks.contains(Int32(event.id)) ? "Remove Bookmark" : "Bookmark") {
                bookmarkAction()
            }.buttonStyle(DefaultButtonStyle())
                .tint(bookmarks.contains(Int32(event.id)) ? .red : .yellow)
        }
    }
}
