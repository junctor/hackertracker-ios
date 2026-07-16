//
//  CustomEventDetailView.swift
//  hackertracker
//
//  Destination for a tap on a custom event row in the schedule.
//  Visually mirrors EventDetailView so the two detail experiences
//  feel like one design system:
//    - Centered large-title header
//    - Frosted gray card with time + location rows and the tags grid
//      (which includes the synthetic "Custom Event" chip)
//    - Markdown body
//    - Editable / deletable via toolbar Edit + a destructive Delete
//      at the bottom (the only piece that differs from EventDetailView,
//      since Firestore events have no edit lifecycle).
//

import CoreData
import MarkdownUI
import SwiftUI

struct CustomEventDetailView: View {
    let eventID: UUID

    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @FetchRequest private var events: FetchedResults<CustomEvent>
    @State private var showingEditor: Bool = false
    @State private var showingDeleteConfirm: Bool = false
    @State private var showingShareSheet: Bool = false
    /// Live bookmark state shared with EventDetailView / EventCellView.
    /// Custom events bookmark under the SAME synthesized Int id that
    /// `Event.from(custom:...)` uses, so toggling the bookmark here
    /// makes the row pop in the Bookmarks (1337) filter too.
    @FetchRequest(sortDescriptors: []) private var bookmarks: FetchedResults<Bookmarks>
    let dfu = DateFormatterUtility.shared

    private func bookmarkInt(_ event: CustomEvent) -> Int {
        CustomEventUtility.notificationID(for: event)
    }
    private func isBookmarked(_ event: CustomEvent) -> Bool {
        let id = Int32(bookmarkInt(event))
        return bookmarks.contains(where: { $0.id == id })
    }

    init(eventID: UUID) {
        self.eventID = eventID
        _events = FetchRequest<CustomEvent>(
            sortDescriptors: [],
            predicate: NSPredicate(format: "id == %@", eventID as CVarArg)
        )
    }

    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        // Phase 4 follow-up: observe DateFormatterUtility so SwiftUI
        // re-renders this view when the active timezone changes.
        let _ = dfu.tzGeneration
        Group {
            if let event = events.first {
                detail(for: event)
            } else {
                ContentUnavailableView(
                    "Event Removed",
                    systemImage: "trash",
                    description: Text("This custom event no longer exists. It may have been deleted on another device.")
                )
                .frame(maxHeight: .infinity)
            }
        }
        .themedBackground(themeManager)
        .navigationBarTitle(Text(""), displayMode: .inline)
        .toolbar {
            // iPad detail pane is rendered without a NavigationStack
            // ancestor (see EventsView's iPad split). The inline
            // action bar in detail(for:) replaces these.
            if !IPadAdaptive.isIPad, let event = events.first {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    // Bookmark toggle. Custom events live on the
                    // schedule unconditionally; bookmarking them is
                    // about opting them into the Bookmarks (1337)
                    // filter rather than visibility.
                    Button {
                        toggleBookmark(event)
                    } label: {
                        Image(systemName: isBookmarked(event) ? "bookmark.fill" : "bookmark")
                    }
                    .accessibilityLabel(isBookmarked(event) ? "Remove bookmark" : "Add bookmark")
                    // One-tap notifications toggle. Goes through
                    // touchAndSave so scheduling / cancellation is
                    // handled by CustomEventUtility automatically.
                    Button {
                        toggleNotifications(event)
                    } label: {
                        Image(systemName: event.notificationsEnabled ? "bell.fill" : "bell.slash")
                    }
                    .accessibilityLabel(event.notificationsEnabled ? "Turn off notifications" : "Turn on notifications")
                    Button {
                        showingShareSheet = true
                    } label: {
                        Image(systemName: "qrcode")
                    }
                    .accessibilityLabel("Share via QR code")
                    Button {
                        showingEditor = true
                    } label: {
                        Image(systemName: "pencil")
                    }
                    .accessibilityLabel("Edit event")
                }
            }
        }
        .sheet(isPresented: $showingEditor) {
            if let event = events.first {
                CustomEventFormView(existing: event)
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let event = events.first {
                CustomEventShareSheet(event: event)
            }
        }
        .analyticsScreen(name: "CustomEventDetailView")
    }

    @ViewBuilder private func detail(for event: CustomEvent) -> some View {
        ScrollView {
            // iPad: the right pane has no NavigationStack, so the
            // .toolbar block is a no-op. Render the same action
            // buttons inline at the top so bookmark / bell / QR /
            // pencil stay reachable.
            if IPadAdaptive.isIPad {
                inlineActionBar(event: event)
            }

            // Header card: title + time + location + tag chips.
            // Mirrors the EventDetailView layout exactly so the two
            // detail screens read as the same component family.
            VStack(alignment: .leading) {
                VStack(alignment: .center) {
                    Text(event.title ?? "Untitled Event")
                        .font(themeManager.largeTitleFont).bold()
                    VStack(alignment: .leading) {
                        whenRow(event: event)
                        if let location = event.location, !location.isEmpty {
                            locationRow(text: location)
                        }
                        ShowEventCellTags(
                            tagIds: [],
                            minWidth: 150,
                            customEvent: true,
                            customColorHex: event.colorHex
                        )
                    }
                }
                .padding()
                .background(themeManager.cardSurface)
                .iPadFlatCorners(15)
            }

            // Description (Markdown-rendered, matches EventDetailView).
            if let desc = event.eventDescription, !desc.isEmpty {
                VStack(alignment: .leading) {
                    Markdown(desc).themedMarkdown(themeManager)
                        .padding()
                }
            }

            // Shared NoteBlock — same widget used by EventDetailView
            // and ContentDetailView so private notes feel uniform
            // across detail screens. One-time migration of any
            // legacy CustomEvent.notes happens in the .task below.
            Divider()
            NoteBlock(targetID: CustomEventUtility.notificationID(for: event), kind: .customEvent)
                .task { migrateLegacyNotesIfNeeded(event) }

            Divider()
            metadataFooter(event: event)
            Divider()

            Button(role: .destructive) {
                showingDeleteConfirm = true
            } label: {
                Label("Delete this event", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.red)
            .padding()
        }
        .confirmationDialog(
            "Delete this event?",
            isPresented: $showingDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                _ = CustomEventUtility.delete(context: viewContext, event: event)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Header rows

    /// Inline iPad action bar — mirrors the toolbar items but renders
    /// in-body so it doesn't require a NavigationStack ancestor.
    @ViewBuilder private func inlineActionBar(event: CustomEvent) -> some View {
        HStack(spacing: 16) {
            Spacer()
            Button {
                toggleBookmark(event)
            } label: {
                Image(systemName: isBookmarked(event) ? "bookmark.fill" : "bookmark")
                    .font(themeManager.title3Font)
            }
            .accessibilityLabel(isBookmarked(event) ? "Remove bookmark" : "Add bookmark")
            Button {
                toggleNotifications(event)
            } label: {
                Image(systemName: event.notificationsEnabled ? "bell.fill" : "bell.slash")
                    .font(themeManager.title3Font)
            }
            .accessibilityLabel(event.notificationsEnabled ? "Turn off notifications" : "Turn on notifications")
            Button {
                showingShareSheet = true
            } label: {
                Image(systemName: "qrcode")
                    .font(themeManager.title3Font)
            }
            .accessibilityLabel("Share via QR code")
            Button {
                showingEditor = true
            } label: {
                Image(systemName: "pencil")
                    .font(themeManager.title3Font)
            }
            .accessibilityLabel("Edit event")
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .tint(.primary)
    }

    @ViewBuilder private func whenRow(event: CustomEvent) -> some View {
        let begin = event.beginTimestamp ?? Date()
        let end = event.endTimestamp ?? begin
        HStack {
            Image(systemName: "clock")
            Text("\(dfu.shortDayMonthDayTimeOfWeekFormatter.string(from: begin)) - \(dfu.shortDayMonthDayTimeOfWeekFormatter.string(from: end))")
                .font(themeManager.subheadlineFont).bold()
        }
        .padding(.leading, 10)
        .padding(.trailing, 5)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(themeManager.cardSurface)
        .cornerRadius(10)
        .padding(.bottom, 5)
    }

    @ViewBuilder private func locationRow(text: String) -> some View {
        HStack {
            Image(systemName: "map")
            Text(text).font(themeManager.subheadlineFont).bold()
        }
        .padding(.leading, 10)
        .padding(.trailing, 5)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(themeManager.cardSurface)
        .cornerRadius(10)
        .padding(.bottom, 5)
    }

    // MARK: - Metadata footer

    @ViewBuilder private func metadataFooter(event: CustomEvent) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            conferenceBadges(event: event)
            notificationsRow(event: event)
        }
        .padding(.horizontal)
    }

    @ViewBuilder private func conferenceBadges(event: CustomEvent) -> some View {
        let codes = CustomEventUtility.conferenceCodes(of: event)
        if codes.isEmpty {
            Label("Applies to every conference", systemImage: "globe")
                .font(themeManager.captionFont)
                .foregroundStyle(.secondary)
        } else {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Image(systemName: "checkmark.circle")
                    .foregroundStyle(.secondary)
                Text(codes.joined(separator: ", "))
                    .font(themeManager.captionFont)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder private func notificationsRow(event: CustomEvent) -> some View {
        Label(
            event.notificationsEnabled ? "Notifications on" : "Notifications off",
            systemImage: event.notificationsEnabled ? "bell.fill" : "bell.slash"
        )
        .font(themeManager.captionFont)
        .foregroundStyle(.secondary)
    }

    // MARK: - Actions

    private func toggleBookmark(_ event: CustomEvent) {
        let id = bookmarkInt(event)
        if isBookmarked(event) {
            BookmarkUtility.deleteBookmark(context: viewContext, id: id)
        } else {
            BookmarkUtility.addBookmark(context: viewContext, id: id)
        }
    }

    private func toggleNotifications(_ event: CustomEvent) {
        event.notificationsEnabled.toggle()
        _ = CustomEventUtility.touchAndSave(context: viewContext, event: event)
    }

    /// Move CustomEvent.notes content into the shared Note store the
    /// first time we render. The form's Notes field has been removed,
    /// so this one-shot migration keeps existing copies visible in
    /// the new NoteBlock. Safe to call repeatedly: the upsert is a
    /// no-op once the Note exists, and we clear CustomEvent.notes
    /// after migration so we don't keep two copies in sync.
    private func migrateLegacyNotesIfNeeded(_ event: CustomEvent) {
        guard let legacy = event.notes,
              !legacy.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let id = CustomEventUtility.notificationID(for: event)
        if NotesUtility.note(context: viewContext, targetID: id, kind: .customEvent) == nil {
            _ = NotesUtility.upsert(context: viewContext, targetID: id, kind: .customEvent, body: legacy)
        }
        event.notes = nil
        _ = CustomEventUtility.touchAndSave(context: viewContext, event: event)
    }
}
