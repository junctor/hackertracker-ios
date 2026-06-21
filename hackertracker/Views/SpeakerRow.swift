//
//  SpeakerRow.swift
//  hackertracker
//
//  Created by Seth W Law on 6/15/22.
//

import SwiftUI

struct SpeakerRow: View {
    var speaker: Speaker
    var themeColor: Color
    @Environment(ThemeManager.self) private var themeManager
    /// Used to look up the speaker's events so we can roll their tag
    /// IDs up into the chip strip below the subtitle.
    @Environment(InfoViewModel.self) private var viewModel
    /// Mirror of the AI summary toggle used by EventCell / ContentCell.
    /// When on AND the speaker lacks a job title, we render a one-line
    /// AI-generated bio summary in the subtitle slot.
    @AppStorage("aiSummaries") private var aiSummaries: Bool = false
    /// Hidden secondary gate — speaker bios are only summarized when
    /// the user discovers + flips the chord-revealed toggle in
    /// Settings → AI Summaries (7-tap on the main row).
    @AppStorage("speakerAISummaries") private var speakerAISummaries: Bool = false

    /// True when both the main AI Summaries toggle AND the hidden
    /// speaker-specific gate are enabled.
    private var aiBiosEnabled: Bool { aiSummaries && speakerAISummaries }

    /// True when the speaker has no provided job-title/subtitle to
    /// render. Both nil and whitespace-only titles count as empty so
    /// data quirks like `" "` don't suppress the fallback chain.
    private var titleIsEmpty: Bool {
        (speaker.title?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) ?? true
    }

    /// Trimmed bio text. Empty string if the speaker has no bio.
    private var trimmedBio: String {
        speaker.description.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Bios under this length are short enough to fit as a subtitle
    /// verbatim. Matches `TalkSummaryCache.minDescriptionChars` so
    /// anything we'd otherwise feed to the on-device LLM is also the
    /// threshold for "long enough that we should summarize instead".
    private static let inlineBioMaxChars = 100

    /// Distinct event titles for this speaker, in `eventIds` order,
    /// comma-joined. Two sessions with the same title get one mention
    /// (a speaker doing two slots of "Hands-on Workshop" shouldn't
    /// list it twice).
    private var eventNamesLine: String {
        var seen = Set<String>()
        let names = speaker.eventIds
            .compactMap { viewModel.eventsById[$0]?.title }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .filter { seen.insert($0).inserted }
        return names.joined(separator: ", ")
    }

    /// Unique tag IDs rolled up across every event this speaker is
    /// associated with, intersected with the same eligibility set
    /// the filter sheet uses (browsable, content-category, not in
    /// `SpeakerListConfig.excludedTagTypeLabels`). Mirroring the
    /// allow-list keeps chips and filter aligned — and drops rogue
    /// tags coming from tagtypes that don't belong on speakers
    /// (e.g. "Tool" demo categories).
    ///
    /// Uses viewModel.eventsById for O(speaker.eventIds) lookup
    /// instead of O(speaker.eventIds × all events).
    private var speakerTagIds: [Int] {
        let eligible: Set<Int> = Set(
            viewModel.tagtypes
                .filter { $0.category == "content" && $0.isBrowsable }
                .filter { !SpeakerListConfig.excludedTagTypeLabels.contains($0.label) }
                .flatMap { $0.tags.map(\.id) }
        )
        let mineTagIds = speaker.eventIds
            .compactMap { viewModel.eventsById[$0]?.tagIds }
            .flatMap { $0 }
        return Array(Set(mineTagIds).intersection(eligible))
    }

    var body: some View {
        HStack {
            Rectangle().fill(themeColor)
                .frame(width: 6)
                .frame(maxHeight: .infinity)
            VStack(alignment: .leading) {
                Text(speaker.name)
                    .font(themeManager.headingFont)
                    .foregroundColor(.primary)
                // Subtitle fallback chain (first match wins):
                //   1. Real job title.
                //   2. Short bio (< 100 chars) — show verbatim. Same
                //      threshold as the AI cache so we never leave a
                //      short bio invisible just because AI is off.
                //   3. AI summary, if user has opted in AND the cache
                //      has produced one for this long-bio speaker.
                //   4. Nothing.
                if let title = speaker.title, !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(title)
                        .font(themeManager.subheadlineFont)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.gray)
                } else if !trimmedBio.isEmpty, trimmedBio.count < Self.inlineBioMaxChars {
                    Text(trimmedBio)
                        .font(themeManager.subheadlineFont)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.gray)
                } else if aiBiosEnabled,
                          let summary = TalkSummaryCache.shared.summary(for: speaker) {
                    // AI summary slot — same styling as the talk-cell
                    // sparkle line. Only reachable when the bio is
                    // long enough that the cache would actually
                    // summarize it.
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
                // Event titles this speaker is presenting. Calendar
                // glyph + comma-joined unique titles. Sits between
                // the subtitle fallback chain and the chip strip so
                // the row reads top-down: who → what they do →
                // what they're presenting → categorical chips.
                if !eventNamesLine.isEmpty {
                    HStack(alignment: .top, spacing: 4) {
                        Image(systemName: "calendar")
                            .font(themeManager.captionFont)
                            .foregroundColor(.gray)
                            .padding(.top, 2)
                        Text(eventNamesLine)
                            .font(themeManager.captionFont)
                            .foregroundColor(.gray)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(.top, 2)
                }
                // Tag chip strip — Event Category / Organizer / etc.
                // rolled up across the speaker's events. Reuses the
                // exact chip renderer the schedule + content rows
                // use so the visual family stays consistent. Skipped
                // when the speaker has no events yet (early load, or
                // a speaker not connected to any tagged event).
                if !speakerTagIds.isEmpty {
                    ShowEventCellTags(tagIds: speakerTagIds)
                        .padding(.top, 2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 10)
            .padding(.trailing, 12)
        }
        // Card treatment parity with EventCell + ContentCell so the
        // speakers list reads as the same design family. Padding lives
        // on the inner content VStack only so the leading color stripe
        // stretches edge-to-edge of the card.
        .background(themeManager.cardSurface)
        .cornerRadius(10)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        // Opportunistic warm on materialization. The cache's own
        // gating handles availability + dedup, but we additionally
        // require titleIsEmpty AND a long bio — otherwise the row
        // would render its title or the short-bio fallback verbatim
        // and the summary would never display.
        .task {
            if aiBiosEnabled,
               titleIsEmpty,
               trimmedBio.count >= Self.inlineBioMaxChars {
                TalkSummaryCache.shared.warm(speaker)
            }
        }
    }
}

struct SpeakerRow_Previews: PreviewProvider {
    static var previews: some View {
        let preview_speaker = Speaker(id: 123_123,
                                      conferenceName: "DEF CON 30",
                                      description: "Description",
                                      link: "https://twitter.com/defcon",
                                      links: [],
                                      media: [],
                                      name: "Speaker Name",
                                      pronouns: "they/them",
                                      twitter: "defcon",
                                      eventIds: [99, 23])
        SpeakerRow(speaker: preview_speaker, themeColor: .purple)
    }
}
