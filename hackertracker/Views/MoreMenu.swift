//
//  MoreMenu.swift
//
//  Created by Caleb Kinney on 5/17/23.
//

import SwiftUI

struct MoreMenu: View {
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
        Menu {
            ShareView(event: event, title: true)
            Button { bookmarkAction() } label: {
                Label(bookmarks.bookmarks.contains(event.id) ? "Remove Bookmark" : "Bookmark",
                      systemImage: bookmarks.bookmarks.contains(event.id) ? "star.fill" : "star")
            }
            Button {} label: {
                Label("Save to Calendar", systemImage: "calendar")
            }
        } label: {
            Image(systemName: "ellipsis")
        }
    }
}
