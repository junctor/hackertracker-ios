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
    @Environment(\.noteContentIDs) private var noteContentIDs
    @Environment(ThemeManager.self) private var themeManager
    let dfu = DateFormatterUtility.shared
    @AppStorage("notifyAt") var notifyAt: Int = 20
    /// Step 3 of the AI summary spike: warm the on-device LLM
    /// cache when this cell materializes IF the user has opted in.
    /// TalkSummaryCache.warm is a no-op when the device can't run
    /// FoundationModels, so this stays safe on iOS < 26.
    @AppStorage("aiSummaries") private var aiSummaries: Bool = false
    /// Whether to present the original description sheet in response
    /// to a long-press. Only used when an AI summary is shown — long-
    /// pressing a cell with no summary is a no-op so we don't compete
    /// with the row's regular NavigationLink tap.
    @State private var showingOriginalDescription: Bool = false

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
                                .font(themeManager.headingFont)
                                .multilineTextAlignment(.leading)
                            if !content.people.isEmpty {
                                Text(content.people.map { p in viewModel.speakersById[p.id]?.name ?? "" }.joined(separator: ", "))
                                    .font(themeManager.subheadlineFont)
                                    .multilineTextAlignment(.leading)
                            }
                            // AI summary slot: only shown when the user
                            // toggle is on AND the cache has a fresh
                            // summary for this content. The sparkle icon
                            // matches the system convention Mail/Messages
                            // use to mark AI-generated text.
                            if aiSummaries,
                               let summary = TalkSummaryCache.shared.summary(for: content) {
                                HStack(alignment: .top, spacing: 4) {
                                    Image(systemName: "sparkles")
                                        .font(themeManager.captionFont)
                                        .foregroundStyle(.secondary)
                                        .padding(.top, 2)
                                    Text(summary)
                                        .font(themeManager.captionFont)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                }
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel("AI summary: \(summary)")
                            }
                            ShowEventCellTags(tagIds: content.tagIds, minWidth: 150)
                        }
                    }

                    HStack(alignment: .center, spacing: 8) {
                        if noteContentIDs.contains(Int32(content.id)) {
                            Image(systemName: "square.and.pencil")
                                .foregroundStyle(.secondary)
                                .accessibilityLabel("Has a saved note")
                        }
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
        // Long-press to peek at the original description, but only
        // when there's a summary on the row to compare against — a
        // bare long-press on a non-AI cell would feel inconsistent.
        .onLongPressGesture(minimumDuration: 0.5) {
            if aiSummaries, TalkSummaryCache.shared.summary(for: content) != nil {
                showingOriginalDescription = true
            }
        }
        .sheet(isPresented: $showingOriginalDescription) {
            ContentDescriptionPeekSheet(
                title: content.title,
                description: content.description
            )
        }
    }
    
    func getEventTagColorBackground() -> Color {
        // Mirrors the EventCellView guard. Content with an empty
        // tagIds array would otherwise crash on the [0] subscript.
        guard let firstTagId = content.tagIds.first,
              let tag = viewModel.tagsById[firstTagId],
              let colorHex = tag.colorBackground,
              let uicolor = UIColor(hex: colorHex) else {
            return .purple
        }
        return Color(uiColor: uicolor)
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

/// Lightweight peek sheet shown via long-press on an AI-summarized
/// row. Surfaces the full source description so the user can verify
/// what the LLM compressed.
struct ContentDescriptionPeekSheet: View {
    let title: String
    let description: String
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(title)
                        .font(.title2.weight(.semibold))
                    Label("Original description", systemImage: "text.alignleft")
                        .font(themeManager.captionFont)
                        .foregroundStyle(.secondary)
                    Text(description)
                        .font(.body)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
    }
}
