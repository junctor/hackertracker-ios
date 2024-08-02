//
//  EventRowView.swift
//
//  Created by Caleb Kinney on 4/8/23.
//

import SwiftUI

struct EventCell: View {
    let event: Event
    let bookmarks: [Int32]
    let showDay: Bool
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var viewModel: InfoViewModel
    let dfu = DateFormatterUtility.shared
    @AppStorage("notifyAt") var notifyAt: Int = 20
    @AppStorage("show24hourtime") var show24hourtime: Bool = true
    

    /*
     func bookmarkAction(id: Int) {
         if bookmarks.map({$0.id}).contains(Int32(id)) {
             print("ContentDetailView: Removing Bookmark \(id)")
             BookmarkUtility.deleteBookmark(context: viewContext, id: id)
             if notExists {
                 NSLog("ContentDetailView: Removing alert for \(item.title) - \(id)")
                 NotificationUtility.removeNotification(id: id)
                 notExists.toggle()
             } else {
                 NSLog("ContentDetailView: No alert exists for \(item.title) - \(id)")
             }
         } else {
             print("ContentDetailView: Adding Bookmark \(id)")
             BookmarkUtility.addBookmark(context: viewContext, id: id)
             if !notExists {
                 NSLog("ContentDetailView: Adding alert for \(item.title) - \(id)")
                 let notDate = s.beginTimestamp.addingTimeInterval(Double((-notifyAt)) * 60)
                 NotificationUtility.scheduleNotification(date: notDate, id: s.id, title: item.title, location: viewModel.locations.first(where: {$0.id == s.locationId})?.name ?? "unknown")
                 notExists.toggle()
             } else {
                 NSLog("ContentDetailView: Alert already exists for \(item.title) - \(id)")
             }
         }
     }*/
    func bookmarkAction() {
        if bookmarks.contains(Int32(event.id)) {
            print("EventCellView: Removing Bookmark \(event.id)")
            BookmarkUtility.deleteBookmark(context: viewContext, id: event.id)
            NotificationUtility.removeNotification(id: event.id)
        } else {
            print("EventCellView: Adding Bookmark \(event.id)")
            BookmarkUtility.addBookmark(context: viewContext, id: event.id)
            let notDate = event.beginTimestamp.addingTimeInterval(Double((-notifyAt)) * 60)
            NotificationUtility.scheduleNotification(date: notDate, id: event.id, title: event.title, location: viewModel.locations.first(where: {$0.id == event.locationId})?.name ?? "unknown")
        }
    }

    var body: some View {
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
                            Text(event.title).font(.headline)
                            if !event.people.isEmpty {
                                Text(event.people.map { p in viewModel.speakers.first(where: { $0.id == p.id })?.name ?? "" }.joined(separator: ", ")).font(.subheadline)
                            }
                            if let l = viewModel.locations.first(where: {$0.id == event.locationId}) {
                                Text(l.name).font(.caption2)
                            }
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
