//
//  MoreMenu.swift
//
//  Created by Caleb Kinney on 5/17/23.
//

import SwiftUI

struct MoreMenu: View {
    let event: Event
    let bookmarks: [Int32]
    @Environment(\.managedObjectContext) private var viewContext

    func bookmarkAction() {
        if bookmarks.contains(Int32(event.id)) {
            BookmarkUtility.deleteBookmark(context: viewContext, id: event.id)
        } else {
            BookmarkUtility.addBookmark(context: viewContext, id: event.id)
        }
    }

    var body: some View {
        Menu {
            ShareView(event: event, title: true)
            Button { bookmarkAction() } label: {
                Label(bookmarks.contains(Int32(event.id)) ? "Remove Bookmark" : "Bookmark",
                      systemImage: bookmarks.contains(Int32(event.id)) ? "bookmark.fill" : "bookmark")
            }
            Button {} label: {
                Label("Save to Calendar", systemImage: "calendar")
            }
        } label: {
            Image(systemName: "ellipsis")
        }
    }
}
