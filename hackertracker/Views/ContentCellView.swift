//
//  EventRowView.swift
//
//  Created by Caleb Kinney on 4/8/23.
//

import SwiftUI

struct ContentCell: View {
    let content: Content
    let bookmarks: [Int32]
    let showDay: Bool
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var viewModel: InfoViewModel
    let dfu = DateFormatterUtility.shared
    @AppStorage("notifyAt") var notifyAt: Int = 20

    func bookmarkAction() {
        for s in content.sessions {
            if bookmarks.contains(Int32(s.id)) {
                print("ContentCell: Removing Bookmark \(s.id)")
                BookmarkUtility.deleteBookmark(context: viewContext, id: s.id)
                NotificationUtility.removeNotification(id: s.id)
            } else {
                print("ContentCell: Adding Bookmark \(s.id)")
                BookmarkUtility.addBookmark(context: viewContext, id: s.id)
                let notDate = s.beginTimestamp.addingTimeInterval(Double((-notifyAt)) * 60)
                NotificationUtility.scheduleNotification(date: notDate, id: s.id, title: content.title, location: viewModel.locations.first(where: {$0.id == s.locationId})?.name ?? "unknown")
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .center) {
                Rectangle().fill(getEventTagColorBackground())
                    .frame(width: 6)
                HStack(alignment: .top) {
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(content.title)
                                .font(.headline)
                                .multilineTextAlignment(.leading)
                            if !content.people.isEmpty {
                                Text(content.people.map { p in viewModel.speakers.first(where: { $0.id == p.id })?.name ?? "" }.joined(separator: ", "))
                                    .font(.subheadline)
                                    .multilineTextAlignment(.leading)
                            }
                            ShowEventCellTags(tagIds: content.tagIds, minWidth: 150)
                        }
                    }
                }
            }
        }
    }
    
    func getEventTagColorBackground() -> Color {
        if let tagtype = viewModel.tagtypes.first(where: {$0.tags.contains(where: {$0.id == content.tagIds[0]})}),
           let tag = tagtype.tags.first(where: { $0.id == content.tagIds[0]}),
           let colorHex = tag.colorBackground, let uicolor = UIColor(hex: colorHex) {
            return Color(uiColor: uicolor)
        }
        return .purple
    }
}

extension Sequence where Iterator.Element : Hashable {

    func intersects<S : Sequence>(with sequence: S) -> Bool
        where S.Iterator.Element == Iterator.Element
    {
        let sequenceSet = Set(sequence)
        return self.contains(where: sequenceSet.contains)
    }
}
