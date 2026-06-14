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
    @Environment(InfoViewModel.self) private var viewModel
    let dfu = DateFormatterUtility.shared
    @AppStorage("notifyAt") var notifyAt: Int = 20
    /// Step 3 of the AI summary spike: warm the on-device LLM
    /// cache when this cell materializes IF the user has opted in.
    /// TalkSummaryCache.warm is a no-op when the device can't run
    /// FoundationModels, so this stays safe on iOS < 26.
    @AppStorage("aiSummaries") private var aiSummaries: Bool = false

    func bookmarkAction() {
        for s in content.sessions {
            if bookmarks.contains(Int32(s.id)) {
                Log.bookmarks.debug("contentCell remove \(s.id)")
                BookmarkUtility.deleteBookmark(context: viewContext, id: s.id)
                NotificationUtility.removeNotification(id: s.id)
            } else {
                Log.bookmarks.debug("contentCell add \(s.id)")
                BookmarkUtility.addBookmark(context: viewContext, id: s.id)
                let notDate = s.beginTimestamp.addingTimeInterval(Double((-notifyAt)) * 60)
                NotificationUtility.scheduleNotification(date: notDate, id: s.id, title: content.title, location: viewModel.locationsById[s.locationId]?.name ?? "unknown")
            }
        }
    }
    
    /// Phase 6 follow-up: a Content has multiple sessions. Visual state mirrors
    /// `bookmarkAction()` semantics (which toggles each session's bookmark
    /// independently) -- we treat the content as "bookmarked" if ANY of its
    /// sessions are bookmarked, so the icon highlights as soon as the user
    /// has saved at least one session.
    private var isBookmarked: Bool {
        content.sessions.contains { bookmarks.contains(Int32($0.id)) }
    }

    /// Red tint when any bookmarked session collides with another bookmark;
    /// matches the conflict pill behavior in EventCell.
    private var hasBookmarkConflict: Bool {
        let bookmarkInts = bookmarks.map { Int($0) }
        return content.sessions.contains { s in
            bookmarks.contains(Int32(s.id)) &&
            viewModel.bookmarkConflicts(eventId: s.id, bookmarks: bookmarkInts)
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
                                Text(content.people.map { p in viewModel.speakersById[p.id]?.name ?? "" }.joined(separator: ", "))
                                    .font(.subheadline)
                                    .multilineTextAlignment(.leading)
                            }
                            ShowEventCellTags(tagIds: content.tagIds, minWidth: 150)
                        }
                    }

                    HStack(alignment: .center) {
                        Button {
                            bookmarkAction()
                        } label: {
                            Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                                .foregroundColor(hasBookmarkConflict ? ThemeColors.red : .primary)
                        }
                        .accessibilityLabel(isBookmarked ? "Remove bookmark" : "Add bookmark")
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .swipeActions {
            Button(isBookmarked ? "Remove Bookmark" : "Bookmark") {
                bookmarkAction()
            }.buttonStyle(DefaultButtonStyle())
                .tint(isBookmarked ? .red : .yellow)
        }
        // LazyVStack inside ContentListView materializes cells as they
        // scroll into view; this .task runs once per materialization.
        // Cheap no-op when aiSummaries is off or the device can't run
        // FoundationModels, and the cache itself dedups concurrent
        // requests so there's no risk of spamming.
        .task {
            if aiSummaries {
                TalkSummaryCache.shared.warm(content)
            }
        }
    }
    
    func getEventTagColorBackground() -> Color {
        if let tag = viewModel.tagsById[content.tagIds[0]],
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
