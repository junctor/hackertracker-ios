//
//  EventRowView.swift
//
//  Created by Caleb Kinney on 4/8/23.
//

import SwiftUI

struct EventCell: View {
    let event: Event
    @EnvironmentObject var bookmarks: oBookmarks

    func bookmarkAction() {
        if bookmarks.bookmarks.contains(event.id) {
            bookmarks.bookmarks.remove(event.id)
            
        } else {
            bookmarks.bookmarks.insert(event.id)
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .center) {
                Rectangle().fill(event.type.swiftuiColor)
                    .frame(width: 6)
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
                        Image(systemName: bookmarks.bookmarks.contains(event.id) ? "star.fill" : "star")
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }

        }.swipeActions {
            Button(bookmarks.bookmarks.contains(event.id) ? "Remove Bookmark" : "Bookmark") {
                bookmarkAction()
            }.buttonStyle(DefaultButtonStyle())
                .tint(bookmarks.bookmarks.contains(event.id) ? .red : .yellow)
        }
    }
}
