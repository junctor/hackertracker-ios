//
//  ReportContentSheet.swift
//  hackertracker
//
//  Message-entry sheet for the "report an issue" feedback flow.
//  Collects a free-text message from the user and submits it via
//  `FeedbackReporter.send` for the given object type/id.
//

import SwiftUI

struct ReportContentSheet: View {
    let objectType: ReportObjectType
    let objectId: Int
    /// Human-readable name of the content being reported (talk title,
    /// speaker name, org name, document title). Shown non-editably so the
    /// submitter can confirm what the report is about. Empty = hide the row.
    var objectName: String = ""

    @Environment(InfoViewModel.self) private var viewModel
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.dismiss) private var dismiss

    @State private var message = ""
    @State private var sending = false
    @State private var errorText: String?
    @State private var sent = false

    /// A conference-level report is general feedback rather than a report
    /// about a specific piece of content, so it uses softer copy.
    private var isGeneralFeedback: Bool { objectType == .conference }

    /// Header shown above the message field.
    private var promptText: String {
        isGeneralFeedback ? "General Feedback" : "What’s wrong with this content?"
    }

    /// Footer under the message field. General feedback drops the first
    /// (illegal/unsafe-content) paragraph and keeps only the second.
    private var footerText: String {
        let handling = "Your message and an anonymous app identifier are sent to the Hacker Tracker team, and may also be shared with the conference organizers. If you would like to receive a response, please reach out to the respective conference organizers instead of submitting a report here. We encourage you to not share personal information here; we do not guarantee a response."
        guard !isGeneralFeedback else { return handling }
        let scope = "Submit a report if you believe that the associated content is illegal or unsafe in your jurisdiction."
        return scope + "\n\n" + handling
    }

    var body: some View {
        NavigationStack {
            Form {
                if !isGeneralFeedback, !objectName.isEmpty {
                    Section {
                        Text(objectName)
                            .font(themeManager.headingFont)
                    } header: {
                        Text("Reporting")
                    }
                }
                Section {
                    TextEditor(text: $message)
                        .frame(minHeight: 140)
                } header: {
                    Text(promptText)
                } footer: {
                    Text(footerText)
                }
            }
            .themedNavTitle("Report an Issue", themeManager)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if sending { ProgressView() }
                    else {
                        Button("Send") { submit() }
                            .disabled(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .alert("Couldn’t Send", isPresented: Binding(get: { errorText != nil }, set: { if !$0 { errorText = nil } })) {
                Button("Retry") { submit() }
                Button("Cancel", role: .cancel) { errorText = nil }
            } message: { Text(errorText ?? "") }
            .alert("Report Sent", isPresented: $sent) {
                Button("OK") { dismiss() }
            } message: { Text("Thanks — the organizers will take a look.") }
        }
    }

    private func submit() {
        guard let conference = viewModel.conference else {
            errorText = "No active conference."; return
        }
        let conferenceId = conference.id
        let conferenceName = conference.name
        errorText = nil
        sending = true
        Task {
            let result = await FeedbackReporter.send(
                message: message.trimmingCharacters(in: .whitespacesAndNewlines),
                conferenceId: conferenceId, conferenceName: conferenceName,
                objectType: objectType, objectId: objectId)
            sending = false
            switch result {
            case .success: sent = true
            case .failure(let e): errorText = e.message
            }
        }
    }
}
