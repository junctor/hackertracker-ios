//
//  CustomEventFormView.swift
//  hackertracker
//
//  Create or edit a locally-stored CustomEvent. Same screen serves
//  both flows: pass `existing: nil` to create, `existing: <event>` to
//  edit. CRUD goes through CustomEventUtility so persistence + the
//  CloudKit sync ride entirely on the existing Core Data stack.
//

import CoreData
import SwiftUI

struct CustomEventFormView: View {
    /// nil when the form is in create mode; the event being edited
    /// otherwise. We snapshot the live values into local @State so
    /// edits can be cancelled cleanly without partial writes.
    let existing: CustomEvent?
    /// Optional pre-fill values, used when the form is launched
    /// from a deep-link import (QR code scan). Ignored when `existing`
    /// is non-nil so edit mode keeps its existing semantics.
    var draft: CustomEventDraft? = nil

    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var selected: SelectedConference
    @Environment(ConferencesViewModel.self) private var consViewModel

    // MARK: - Field state

    @State private var title: String = ""
    @State private var eventDescription: String = ""
    @State private var begin: Date = Date()
    @State private var end: Date = Date().addingTimeInterval(60 * 60)
    @State private var location: String = ""
    @State private var notes: String = ""
    @State private var notificationsEnabled: Bool = false
    @State private var accentColor: Color = .purple
    /// Set of conference codes this event applies to. Empty set means
    /// "every conference" (mirrors Event.from(custom:conferenceCode:)).
    @State private var selectedConferences: Set<String> = []

    @State private var showingDeleteConfirm: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Event title", text: $title)
                        .textInputAutocapitalization(.words)
                } header: { Text("Title") }

                Section {
                    DatePicker("Starts", selection: $begin)
                    DatePicker("Ends", selection: $end, in: begin...)
                } header: { Text("When") }

                Section {
                    TextField("Location (optional)", text: $location)
                        .textInputAutocapitalization(.words)
                } header: { Text("Where") }

                Section {
                    TextEditor(text: $eventDescription)
                        .frame(minHeight: 80)
                } header: { Text("Description") }

                // Notes moved to the shared NoteBlock on detail
                // screens — every event, content item, and custom
                // event now uses the same store. The form no longer
                // shows a Notes field; legacy data is preserved on
                // first read of the detail screen.
                Section {
                    ColorPicker("Accent color", selection: $accentColor, supportsOpacity: false)
                } header: { Text("Appearance") }

                Section {
                    Toggle("Send a notification before this event", isOn: $notificationsEnabled)
                } footer: {
                    Text("Uses the global \"Before Event\" minutes setting. Defaults off.")
                }

                Section {
                    if consViewModel.conferences.isEmpty {
                        Text("No conferences loaded yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(consViewModel.conferences, id: \.code) { conf in
                            Toggle(conf.name, isOn: bindingFor(code: conf.code))
                        }
                    }
                } header: { Text("Applies to") } footer: {
                    Text("Pick one or more conferences. If none are picked, this event shows on every conference's schedule.")
                }

                if existing != nil {
                    Section {
                        Button(role: .destructive) {
                            showingDeleteConfirm = true
                        } label: {
                            Label("Delete event", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle(existing == nil ? "New Event" : "Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!isValid)
                }
            }
            .onAppear { hydrateFromExisting() }
            .confirmationDialog(
                "Delete this event?",
                isPresented: $showingDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) { deleteAndDismiss() }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    // MARK: - Validation + save

    /// Bare-minimum gate: title is non-blank and end >= begin.
    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && end >= begin
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = eventDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLocation = location.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let codes = Array(selectedConferences).sorted()
        let hex = accentColor.toHexString()

        if let existing {
            existing.title = trimmedTitle
            existing.eventDescription = trimmedDescription.isEmpty ? nil : trimmedDescription
            existing.beginTimestamp = begin
            existing.endTimestamp = end
            existing.location = trimmedLocation.isEmpty ? nil : trimmedLocation
            existing.notes = trimmedNotes.isEmpty ? nil : trimmedNotes
            existing.conferenceCodes = codes as NSArray
            existing.colorHex = hex
            existing.notificationsEnabled = notificationsEnabled
            _ = CustomEventUtility.touchAndSave(context: viewContext, event: existing)
        } else {
            _ = CustomEventUtility.create(
                context: viewContext,
                title: trimmedTitle,
                eventDescription: trimmedDescription.isEmpty ? nil : trimmedDescription,
                beginTimestamp: begin,
                endTimestamp: end,
                location: trimmedLocation.isEmpty ? nil : trimmedLocation,
                notes: trimmedNotes.isEmpty ? nil : trimmedNotes,
                conferenceCodes: codes,
                colorHex: hex,
                notificationsEnabled: notificationsEnabled
            )
        }
        dismiss()
    }

    private func deleteAndDismiss() {
        guard let existing else { return }
        _ = CustomEventUtility.delete(context: viewContext, event: existing)
        dismiss()
    }

    // MARK: - Helpers

    private func bindingFor(code: String) -> Binding<Bool> {
        Binding(
            get: { selectedConferences.contains(code) },
            set: { isOn in
                if isOn { selectedConferences.insert(code) }
                else    { selectedConferences.remove(code) }
            }
        )
    }

    /// Populate @State from `existing` (edit mode) > `draft` (inbound
    /// QR import) > defaults (fresh create).
    private func hydrateFromExisting() {
        if let e = existing {
            title = e.title ?? ""
            eventDescription = e.eventDescription ?? ""
            begin = e.beginTimestamp ?? Date()
            end = e.endTimestamp ?? begin.addingTimeInterval(60 * 60)
            location = e.location ?? ""
            notes = e.notes ?? ""
            notificationsEnabled = e.notificationsEnabled
            if let hex = e.colorHex, let ui = UIColor(hex: hex) {
                accentColor = Color(uiColor: ui)
            }
            selectedConferences = Set(CustomEventUtility.conferenceCodes(of: e))
        } else if let d = draft {
            // Pre-fill from a scanned QR. Notes are intentionally not
            // shared so they stay empty.
            title = d.title
            eventDescription = d.eventDescription ?? ""
            begin = d.begin
            end = d.end
            location = d.location ?? ""
            notificationsEnabled = d.notificationsEnabled
            if let hex = d.colorHex, let ui = UIColor(hex: hex) {
                accentColor = Color(uiColor: ui)
            }
            // Default to the union of the scanned codes and the user's
            // current conference, so a scanned event from a different
            // conference can land on the user's active one too.
            var codes = Set(d.conferenceCodes)
            codes.insert(selected.code)
            selectedConferences = codes
        } else {
            // Default to the currently-selected conference so the common
            // case ("add an event to THIS conference") is one tap.
            selectedConferences = [selected.code]
        }
    }
}

private extension Color {
    /// Best-effort conversion to a stable hex string for Core Data
    /// persistence. SwiftUI Color doesn't expose RGBA directly; round-trip
    /// through UIColor.
    func toHexString() -> String? {
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard ui.getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        let R = Int(round(r * 255)), G = Int(round(g * 255)), B = Int(round(b * 255))
        return String(format: "#%02X%02X%02X", R, G, B)
    }
}
