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
    @Environment(ThemeManager.self) private var themeManager
    let dfu = DateFormatterUtility.shared
    @AppStorage("notifyAt") var notifyAt: Int = 20
    @AppStorage("show24hourtime") var show24hourtime: Bool = true
    /// Mirror of ContentCellView's AI summary plumbing — Schedule
    /// tab rows now opt into on-device summaries the same way.
    @AppStorage("aiSummaries") private var aiSummaries: Bool = false
    @State private var showingOriginalDescription: Bool = false
    @FetchRequest(sortDescriptors: []) var bookmarks: FetchedResults<Bookmarks>
    /// Set of event ids that have a saved private Note. Published by
    /// EventsView (which holds the single Note FetchRequest); defaults
    /// to empty when this cell renders inside a screen that doesn't
    /// publish the value (GlobalSearchView, SharedScheduleView, etc.).
    @Environment(\.noteEventIDs) private var noteEventIDs
    /// Mirror for content-kind notes — same talk may have been noted
    /// from the All-Content side; the pencil should still appear here.
    @Environment(\.noteContentIDs) private var noteContentIDs
    

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
                                    .font(themeManager.subheadlineFont)
                                    .padding(.bottom, 3)
                            }
                            Text(show24hourtime ? dfu.hourMinuteTimeFormatter.string(from: event.beginTimestamp) : dfu.hourMinute12TimeFormatter.string(from: event.beginTimestamp))
                                .font(themeManager.subheadlineFont)
                            if event.beginTimestamp != event.endTimestamp {
                                Text(show24hourtime ? dfu.hourMinuteTimeFormatter.string(from: event.endTimestamp) : dfu.hourMinute12TimeFormatter.string(from: event.endTimestamp))
                                    .font(themeManager.captionFont)
                            }
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(event.title)
                                .font(themeManager.headingFont)
                                .multilineTextAlignment(.leading)
                            if !event.people.isEmpty {
                                Text(event.people.map { p in viewModel.speakersById[p.id]?.name ?? "" }.joined(separator: ", "))
                                    .font(themeManager.subheadlineFont)
                                    .multilineTextAlignment(.leading)
                            }
                            if let l = viewModel.locationsById[event.locationId] {
                                Text(l.name).font(themeManager.captionFont)
                                    .multilineTextAlignment(.leading)
                            }
                            // AI summary slot. Same gating and styling as
                            // ContentCellView so Schedule + All Content
                            // share the affordance.
                            if aiSummaries,
                               let summary = TalkSummaryCache.shared.summary(for: event) {
                                HStack(alignment: .top, spacing: 4) {
                                    Image(systemName: "sparkles")
                                        .font(themeManager.captionFont)
                                        .foregroundColor(.gray)
                                        .padding(.top, 2)
                                    Text(summary)
                                        .font(themeManager.captionFont)
                                        .foregroundColor(.gray)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                }
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel("AI summary: \(summary)")
                            }
                            ShowEventCellTags(
                                tagIds: event.tagIds,
                                customEvent: event.customEventID != nil,
                                customColorHex: event.customColorHex
                            )
                        }
                    }
                    
                    HStack(alignment: .center, spacing: 8) {
                        // Pencil badge appears when this row has a
                        // saved private note. Tap-through to the row's
                        // NavigationLink — the badge is purely
                        // informational, not independently interactive.
                        // Pencil lights up when the event id has a
                        // note OR when the event's contentId has a
                        // note authored from the All-Content side.
                        if noteEventIDs.contains(Int32(event.id))
                            || noteContentIDs.contains(Int32(event.contentId)) {
                            Image(systemName: "square.and.pencil")
                                .foregroundStyle(.secondary)
                                .accessibilityLabel("Has a saved note")
                        }
                        Button {
                            bookmarkAction()
                        } label: {
                            Image(systemName: bookmarkIds.contains(Int32(event.id)) ? "bookmark.fill" : "bookmark")
                                .foregroundColor((bookmarkIds.contains(Int32(event.id)) && viewModel.bookmarkConflicts(eventId: event.id, bookmarks: bookmarkIntsForConflict)) ? themeManager.danger : .primary)
                        }
                        .accessibilityLabel(
                            bookmarkIds.contains(Int32(event.id))
                                ? (viewModel.bookmarkConflicts(eventId: event.id, bookmarks: bookmarkIntsForConflict)
                                    ? "Bookmarked, conflicts with another event"
                                    : "Remove bookmark")
                                : "Add bookmark"
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.vertical, 10)
                .padding(.trailing, 12)
            }

        }
        .background(themeManager.cardSurface)
        .cornerRadius(10)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .swipeActions {
            Button(bookmarkIds.contains(Int32(event.id)) ? "Remove Bookmark" : "Bookmark") {
                bookmarkAction()
            }.buttonStyle(DefaultButtonStyle())
                .tint(bookmarkIds.contains(Int32(event.id)) ? .red : .yellow)
        }
        // Opportunistic warm on cell materialization, mirroring
        // ContentCellView. Gated on user toggle + cache's own
        // capability + 100-char checks.
        .task {
            if aiSummaries {
                TalkSummaryCache.shared.warm(event)
            }
        }
        // Long-press peeks at the original description, but only
        // when a summary is being displayed.
        .onLongPressGesture(minimumDuration: 0.5) {
            if aiSummaries, TalkSummaryCache.shared.summary(for: event) != nil {
                showingOriginalDescription = true
            }
        }
        .sheet(isPresented: $showingOriginalDescription) {
            ContentDescriptionPeekSheet(
                title: event.title,
                description: event.description
            )
        }
    }
    
    func getEventTagColorBackground() -> Color {
        // Custom events override the tag-derived color with whatever
        // the user picked in the form. Falls back to the default if
        // the stored hex is unparseable.
        if let customHex = event.customColorHex,
           let ui = UIColor(hex: customHex) {
            return Color(uiColor: ui)
        }
        // Otherwise: first-tag color, guarded with .first so an empty
        // tagIds array (custom event with no override, or any sparse
        // Firestore data) can't crash. Default is .purple to match
        // the historical fallback.
        guard let firstTagId = event.tagIds.first,
              let tag = viewModel.tagsById[firstTagId],
              let colorHex = tag.colorBackground,
              let uicolor = UIColor(hex: colorHex) else {
            return .purple
        }
        return Color(uiColor: uicolor)
    }
}

struct ShowEventCellTags: View {
    var tagIds: [Int]
    var minWidth: CGFloat = 100
    @Environment(ThemeManager.self) private var themeManager
    /// When true, prepend a synthetic "Custom Event" chip ahead of
    /// the regular tag chips. Honors `customColorHex` when set so the
    /// chip's dot matches the row stripe color the user picked.
    var customEvent: Bool = false
    var customColorHex: String? = nil
    @Environment(InfoViewModel.self) private var viewModel

    private var customChipColor: Color {
        if let hex = customColorHex, let ui = UIColor(hex: hex) {
            return Color(uiColor: ui)
        }
        return .purple
    }

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: minWidth))], alignment: .leading, spacing: 1) {
            if customEvent {
                HStack {
                    Circle().foregroundColor(customChipColor)
                        .frame(width: 8, height: 8, alignment: .center)
                    Text("Custom Event").font(themeManager.captionFont)
                        .multilineTextAlignment(.leading)
                        .frame(alignment: .leading)
                }
            }
            ForEach(tagIds, id: \.self) { tagId in
                if let tag = viewModel.tagsById[tagId] {
                    VStack {
                        HStack {
                            Circle().foregroundColor(Color(UIColor(hex: tag.colorBackground ?? "#2c8f07") ?? .purple))
                                .frame(width: 8, height: 8, alignment: .center)
                            Text(tag.label).font(themeManager.captionFont)
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
