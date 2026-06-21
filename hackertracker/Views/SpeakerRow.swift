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
    /// Mirror of the AI summary toggle used by EventCell / ContentCell.
    /// When on AND the speaker lacks a job title, we render a one-line
    /// AI-generated bio summary in the subtitle slot.
    @AppStorage("aiSummaries") private var aiSummaries: Bool = false

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
                } else if aiSummaries,
                          let summary = TalkSummaryCache.shared.summary(for: speaker) {
                    // AI summary slot — same styling as the talk-cell
                    // sparkle line. Only reachable when the bio is
                    // long enough that the cache would actually
                    // summarize it.
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
            if aiSummaries,
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
