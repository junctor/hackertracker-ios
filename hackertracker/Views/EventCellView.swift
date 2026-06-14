//
//  EventRowView.swift
//
//  Created by Caleb Kinney on 4/8/23.
//

import SwiftUI

struct EventCell: View {
    let event: Event
    // let bookmarks: [Int32]
    let showDay: Bool
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(InfoViewModel.self) private var viewModel
    let dfu = DateFormatterUtility.shared
    @AppStorage("notifyAt") var notifyAt: Int = 20
    @AppStorage("show24hourtime") var show24hourtime: Bool = true
    @FetchRequest(sortDescriptors: []) var bookmarks: FetchedResults<Bookmarks>
    

    func bookmarkAction() {
        let bookmarkIds = Set(bookmarks.map(\.id))
        if bookmarkIds.contains(Int32(event.id)) {
            Log.bookmarks.debug("eventCell remove \(event.id)")
            BookmarkUtility.deleteBookmark(context: viewContext, id: event.id)
            NotificationUtility.removeNotification(id: event.id)
        } else {
            Log.bookmarks.debug("eventCell add \(event.id)")
            BookmarkUtility.addBookmark(context: viewContext, id: event.id)
            let notDate = event.beginTimestamp.addingTimeInterval(Double((-notifyAt)) * 60)
            NotificationUtility.scheduleNotification(date: notDate, id: event.id, title: event.title, location: viewModel.locationsById[event.locationId]?.name ?? "unknown")
        }
    }

    var body: some View {
        // Phase 4 follow-up: observe DateFormatterUtility so SwiftUI
        // re-renders this view when the active timezone changes.
        let _ = dfu.tzGeneration
        let bookmarkIds = Set(bookmarks.map(\.id))
        let bookmarkIntsForConflict = bookmarks.map { Int($0.id) }
        VStack(alignment: .leading) {
            HStack(alignment: .center) {
                Rectangle().fill(getEventTagColorBackground())
                    .frame(width: 6)
                HStack(alignment: .top) {
                    HStack(alignment: .center) {
                        VStack(spacing: 0) {
                            if showDay {
                                Text(dfu.monthDayFormatter.string(from: event.beginTimestamp))
                                    .font(.subheadline)
                                    .padding(.bottom, 3)
                            }
                            Text(show24hourtime ? dfu.hourMinuteTimeFormatter.string(from: event.beginTimestamp) : dfu.hourMinute12TimeFormatter.string(from: event.beginTimestamp))
                                .font(.subheadline)
                            if event.beginTimestamp != event.endTimestamp {
                                Text(show24hourtime ? dfu.hourMinuteTimeFormatter.string(from: event.endTimestamp) : dfu.hourMinute12TimeFormatter.string(from: event.endTimestamp))
                                    .font(.caption2)
                            }
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(event.title)
                                .font(.headline)
                                .multilineTextAlignment(.leading)
                            if !event.people.isEmpty {
                                Text(event.people.map { p in viewModel.speakersById[p.id]?.name ?? "" }.joined(separator: ", "))
                                    .font(.subheadline)
                                    .multilineTextAlignment(.leading)
                            }
                            if let l = viewModel.locationsById[event.locationId] {
                                Text(l.name).font(.caption2)
                                    .multilineTextAlignment(.leading)
                            }
                            ShowEventCellTags(tagIds: event.tagIds)
                        }
                    }
                    
                    HStack(alignment: .center) {
                        Button {
                            bookmarkAction()
                        } label: {
                            Image(systemName: bookmarkIds.contains(Int32(event.id)) ? "bookmark.fill" : "bookmark")
                                .foregroundColor((bookmarkIds.contains(Int32(event.id)) && viewModel.bookmarkConflicts(eventId: event.id, bookmarks: bookmarkIntsForConflict)) ? ThemeColors.red : .primary)
                        }
                        .accessibilityLabel(bookmarkIds.contains(Int32(event.id)) ? "Remove bookmark" : "Add bookmark")
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }

        }.swipeActions {
            Button(bookmarkIds.contains(Int32(event.id)) ? "Remove Bookmark" : "Bookmark") {
                bookmarkAction()
            }.buttonStyle(DefaultButtonStyle())
                .tint(bookmarkIds.contains(Int32(event.id)) ? .red : .yellow)
        }
    }
    
    func getEventTagColorBackground() -> Color {
        if let tag = viewModel.tagsById[event.tagIds[0]],
           let colorHex = tag.colorBackground, let uicolor = UIColor(hex: colorHex) {
            return Color(uiColor: uicolor)
        }
        return .purple
    }
}

struct ShowEventCellTags: View {
    var tagIds: [Int]
    var minWidth: CGFloat = 100
    @Environment(InfoViewModel.self) private var viewModel

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: minWidth))], alignment: .leading, spacing: 1) {
            ForEach(tagIds, id: \.self) { tagId in
                if let tag = viewModel.tagsById[tagId] {
                    VStack {
                        HStack {
                            Circle().foregroundColor(Color(UIColor(hex: tag.colorBackground ?? "#2c8f07") ?? .purple))
                                .frame(width: 8, height: 8, alignment: .center)
                            Text(tag.label).font(.caption)
                                .multilineTextAlignment(.leading)
                                .frame(alignment: .leading)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
