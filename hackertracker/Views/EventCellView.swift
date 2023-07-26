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
    @EnvironmentObject var viewModel: InfoViewModel
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
                Rectangle().fill(getEventTagColorBackground())
                    .frame(width: 6)
                HStack(alignment: .top) {
                    HStack(alignment: .center) {
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
                            ShowEventCellTags(tagIds: event.tagIds)
                        }
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
            }

        }.swipeActions {
            Button(bookmarks.contains(Int32(event.id)) ? "Remove Bookmark" : "Bookmark") {
                bookmarkAction()
            }.buttonStyle(DefaultButtonStyle())
                .tint(bookmarks.contains(Int32(event.id)) ? .red : .yellow)
        }
    }
    
    func getEventTagColorBackground() -> Color {
        if let tagtype = viewModel.tagtypes.first(where: {$0.tags.contains(where: {$0.id == event.tagIds[0]})}),
           let tag = tagtype.tags.first(where: { $0.id == event.tagIds[0]}),
           let colorHex = tag.colorBackground, let uicolor = UIColor(hex: colorHex) {
            return Color(uiColor: uicolor)
        }
        return .purple
    }
}

struct ShowEventCellTags: View {
    var tagIds: [Int]
    @EnvironmentObject var viewModel: InfoViewModel
    let gridItemLayout = [GridItem(.adaptive(minimum: 80))]

    var body: some View {
        LazyVGrid(columns: gridItemLayout, alignment: .leading, spacing: 2) {
            ForEach(tagIds, id: \.self) { tagId in
                if let tagtype = viewModel.tagtypes.first(where: { $0.tags.contains(where: {$0.id == tagId})}), let tag = tagtype.tags.first(where: {$0.id == tagId}) {
                    VStack {
                        HStack {
                            Circle().foregroundColor(Color(UIColor(hex: tag.colorBackground ?? "#2c8f07") ?? .purple))
                                .frame(width: 8, height: 8, alignment: .center)
                            Text(tag.label).font(.caption)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
