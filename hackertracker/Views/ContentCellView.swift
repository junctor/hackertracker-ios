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

    func bookmarkAction() {
        for s in content.sessions {
            if bookmarks.contains(Int32(s.id)) {
                print("EventCellView: Removing Bookmark \(s.id)")
                BookmarkUtility.deleteBookmark(context: viewContext, id: s.id)
            } else {
                print("EventCellView: Adding Bookmark \(s.id)")
                BookmarkUtility.addBookmark(context: viewContext, id: s.id)
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
                            Text(content.title).font(.headline)
                            if !content.people.isEmpty {
                                Text(content.people.map { p in viewModel.speakers.first(where: { $0.id == p.id })?.name ?? "" }.joined(separator: ", ")).font(.subheadline)
                            }
                            ShowEventCellTags(tagIds: content.tagIds)
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
