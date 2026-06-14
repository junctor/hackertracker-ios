//
//  CustomEventDetailView.swift
//  hackertracker
//
//  Destination for a tap on a custom event row in the schedule. Shows
//  the human-readable fields and offers Edit / Delete via the toolbar.
//  Fetches by UUID via @FetchRequest so the view auto-refreshes when
//  the underlying Core Data row is edited or deleted (e.g. CloudKit
//  sync arrives from another device).
//

import CoreData
import SwiftUI

struct CustomEventDetailView: View {
    let eventID: UUID

    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @FetchRequest private var events: FetchedResults<CustomEvent>
    @State private var showingEditor: Bool = false
    @State private var showingDeleteConfirm: Bool = false

    /// FetchRequest needs a predicate referencing `eventID`. Init wires
    /// it up so each instance scopes to a single row.
    init(eventID: UUID) {
        self.eventID = eventID
        _events = FetchRequest<CustomEvent>(
            sortDescriptors: [],
            predicate: NSPredicate(format: "id == %@", eventID as CVarArg)
        )
    }

    var body: some View {
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
        .navigationTitle("Event")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            if let event = events.first {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingEditor = true
                    } label: {
                        Image(systemName: "pencil")
                    }
                    .accessibilityLabel("Edit event")
                    .accessibilityIdentifier("EditCustomEvent")
                    .opacity(event.id == nil ? 0 : 1) // hide if mid-deletion race
                }
            }
        }
        .sheet(isPresented: $showingEditor) {
            if let event = events.first {
                CustomEventFormView(existing: event)
            }
        }
        .iPadReadableContent()
    }

    @ViewBuilder private func detail(for event: CustomEvent) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let title = event.title, !title.isEmpty {
                    Text(title)
                        .font(.largeTitle.weight(.bold))
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                whenSection(event: event)
                if let location = event.location, !location.isEmpty {
                    Label(location, systemImage: "mappin.and.ellipse")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                if let desc = event.eventDescription, !desc.isEmpty {
                    Divider()
                    Text("Description")
                        .font(.headline)
                    Text(desc)
                        .font(.body)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                if let notes = event.notes, !notes.isEmpty {
                    Divider()
                    Text("Notes")
                        .font(.headline)
                    Text(notes)
                        .font(.body)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
                conferenceBadges(event: event)
                notificationsRow(event: event)
                Divider()
                Button(role: .destructive) {
                    showingDeleteConfirm = true
                } label: {
                    Label("Delete this event", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
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

    @ViewBuilder private func whenSection(event: CustomEvent) -> some View {
        let dfu = DateFormatterUtility.shared
        let begin = event.beginTimestamp ?? Date()
        let end = event.endTimestamp ?? begin
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "calendar")
                Text(dfu.dayMonthDayOfWeekFormatter.string(from: begin))
            }
            HStack {
                Image(systemName: "clock")
                Text("\(dfu.hourMinuteTimeFormatter.string(from: begin)) – \(dfu.hourMinuteTimeFormatter.string(from: end))")
                    .monospacedDigit()
            }
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
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
