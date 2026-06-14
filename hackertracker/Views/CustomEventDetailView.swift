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
    let dfu = DateFormatterUtility.shared

    init(eventID: UUID) {
        self.eventID = eventID
        _events = FetchRequest<CustomEvent>(
            sortDescriptors: [],
            predicate: NSPredicate(format: "id == %@", eventID as CVarArg)
        )
    }

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
        .navigationBarTitle(Text(""), displayMode: .inline)
        .toolbar {
            if events.first != nil {
                ToolbarItemGroup(placement: .topBarTrailing) {
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
        .iPadReadableContent()
        .analyticsScreen(name: "CustomEventDetailView")
    }

    @ViewBuilder private func detail(for event: CustomEvent) -> some View {
        ScrollView {
            // Header card: title + time + location + tag chips.
            // Mirrors the EventDetailView layout exactly so the two
            // detail screens read as the same component family.
            VStack(alignment: .leading) {
                VStack(alignment: .center) {
                    Text(event.title ?? "Untitled Event")
                        .font(.largeTitle).bold()
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
                .background(Color(.systemGray6))
                .cornerRadius(15)
            }

            // Description (Markdown-rendered, matches EventDetailView).
            if let desc = event.eventDescription, !desc.isEmpty {
                VStack(alignment: .leading) {
                    Markdown(desc)
                        .padding()
                }
            }

            // Notes — private to the user; EventDetailView has no
            // parallel concept, so render under its own header.
            if let notes = event.notes, !notes.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(.headline)
                    Text(notes)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .padding()
            }

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

    @ViewBuilder private func whenRow(event: CustomEvent) -> some View {
        let begin = event.beginTimestamp ?? Date()
        let end = event.endTimestamp ?? begin
        HStack {
            Image(systemName: "clock")
            Text("\(dfu.shortDayMonthDayTimeOfWeekFormatter.string(from: begin)) - \(dfu.shortDayMonthDayTimeOfWeekFormatter.string(from: end))")
                .font(.subheadline).bold()
        }
        .padding(.leading, 10)
        .padding(.trailing, 5)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .cornerRadius(10)
        .padding(.bottom, 5)
    }

    @ViewBuilder private func locationRow(text: String) -> some View {
        HStack {
            Image(systemName: "map")
            Text(text).font(.subheadline).bold()
        }
        .padding(.leading, 10)
        .padding(.trailing, 5)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
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
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Image(systemName: "checkmark.circle")
                    .foregroundStyle(.secondary)
                Text(codes.joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder private func notificationsRow(event: CustomEvent) -> some View {
        Label(
            event.notificationsEnabled ? "Notifications on" : "Notifications off",
            systemImage: event.notificationsEnabled ? "bell.fill" : "bell.slash"
        )
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}
