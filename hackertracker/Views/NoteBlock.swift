//
//  NoteBlock.swift
//  hackertracker
//
//  Shared "private notes" block that drops onto any detail screen
//  (event, content, custom event). Renders the stored Markdown body
//  read-only, falls back to an "Add a note" affordance when empty,
//  and presents NoteEditorView on tap.
//
//  Notes live in a single Core Data entity keyed by (targetID,
//  targetKind), so this view is the only thing call sites need to
//  drop in — no per-target plumbing required.
//

import MarkdownUI
import SwiftUI

struct NoteBlock: View {
    let targetID: Int
    let kind: NoteKind

    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest private var notes: FetchedResults<Note>
    @State private var showingEditor: Bool = false
    /// Hidden by default — the section is opt-in on every detail
    /// screen. Per-target persistence felt like overkill so this is
    /// ephemeral @State; collapsing on dismiss + re-open is fine.
    @State private var expanded: Bool = false

    /// Scope the FetchRequest to the supplied target. Init wires it
    /// up so each NoteBlock listens for changes to its row only —
    /// CloudKit sync from another device automatically refreshes
    /// the body inline.
    init(targetID: Int, kind: NoteKind) {
        self.targetID = targetID
        self.kind = kind
        _notes = FetchRequest<Note>(
            sortDescriptors: [NSSortDescriptor(keyPath: \Note.updatedAt, ascending: false)],
            predicate: NSPredicate(format: "targetID == %d AND targetKind == %@", Int32(targetID), kind.rawValue)
        )
    }

    private var body_text: String? {
        notes.first?.body.flatMap { $0.isEmpty ? nil : $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Always-visible header. Tap anywhere to expand/collapse;
            // chevron rotates so the affordance reads even without
            // the body being on screen. A small (\u{2022}) dot appears when
            // a note exists so users can tell at a glance whether the
            // collapsed row holds content.
            // Header matches the Show / Hide pattern used by OrgView /
            // SpeakerDetailView / ContentDetailView collapsible sections.
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "note.text")
                        .foregroundStyle(.secondary)
                    Text("My Notes")
                        .font(.headline)
                    if body_text != nil {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 6, height: 6)
                            .accessibilityHidden(true)
                    }
                    Spacer()
                    if expanded {
                        Text("Hide")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.down")
                            .foregroundColor(.secondary)
                    } else {
                        Text("Show")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("My Notes")
            .accessibilityHint(expanded ? "Hide note" : "Show note")

            if expanded {
                Group {
                    if let text = body_text {
                        Markdown(text)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .onTapGesture { showingEditor = true }
                            .accessibilityAddTraits(.isButton)
                            .accessibilityHint("Tap to edit your note")
                    } else {
                        Button {
                            showingEditor = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle")
                                Text("Add a note")
                                Spacer()
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .foregroundStyle(.primary)
                        }
                        .buttonStyle(.plain)
                    }
                    Text("Notes are stored privately on your device and synced via iCloud.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .sheet(isPresented: $showingEditor) {
            NoteEditorView(targetID: targetID, kind: kind, initialBody: notes.first?.body ?? "")
                .environment(\.managedObjectContext, viewContext)
        }
    }
}

/// Modal editor for the shared Note. TextEditor on the left tab,
/// MarkdownUI preview on the right so the user can preview formatting
/// without leaving the sheet. Save persists via NotesUtility; Cancel
/// discards.
struct NoteEditorView: View {
    let targetID: Int
    let kind: NoteKind
    let initialBody: String

    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var body_text: String = ""
    @State private var tab: Tab = .write

    private enum Tab: String, CaseIterable, Identifiable {
        case write = "Write"
        case preview = "Preview"
        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Mode", selection: $tab) {
                    ForEach(Tab.allCases) { t in Text(t.rawValue).tag(t) }
                }
                .pickerStyle(.segmented)
                .padding()

                if tab == .write {
                    TextEditor(text: $body_text)
                        .font(.body.monospaced())
                        .padding(.horizontal, 8)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        if body_text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text("Nothing to preview yet.")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .padding()
                        } else {
                            Markdown(body_text)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                        }
                    }
                }
            }
            .navigationTitle("Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        NotesUtility.upsert(context: viewContext, targetID: targetID, kind: kind, body: body_text)
                        dismiss()
                    }
                }
            }
            .onAppear {
                body_text = initialBody
            }
        }
    }
}
