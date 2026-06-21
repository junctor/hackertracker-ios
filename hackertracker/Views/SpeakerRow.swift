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
    /// data quirks like `" "` don't suppress the summary fallback.
    private var titleIsEmpty: Bool {
        (speaker.title?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) ?? true
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
                if let title = speaker.title, !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(title)
                        .font(themeManager.subheadlineFont)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.gray)
                } else if aiSummaries,
                          let summary = TalkSummaryCache.shared.summary(for: speaker) {
                    // AI summary slot — only when there's no title to
                    // show. Same styling as the talk-cell sparkle line.
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
        // gating handles minDescriptionChars + availability + dedup,
        // so the only thing we owe it here is the "title is empty"
        // filter — otherwise we'd burn battery generating summaries
        // we'll never display.
        .task {
            if aiSummaries && titleIsEmpty {
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
