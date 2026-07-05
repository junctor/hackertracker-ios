//
//  ConferenceRow.swift
//  hackertracker
//
//  Created by Seth W Law on 6/7/22.
//

import Kingfisher
import SwiftUI

struct ConferenceRow: View {
    var conference: Conference
    var code: String

    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let isActive = conference.code == code
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Text(conference.name)
                    .font(themeManager.title3Font)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if isActive {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(themeManager.title3Font)
                }
            }
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    if conference.startDate == conference.endDate {
                        Text(conference.endDate)
                            .font(themeManager.bodyFont)
                    } else {
                        Text("\(conference.startDate) - \(conference.endDate)")
                            .font(themeManager.bodyFont)
                    }
                    // Polish: surface the conference timezone so users can see at
                    // a glance which timezone the schedule renders in.
                    if let tz = conference.timezone, !tz.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                            Text(tz)
                        }
                        .font(themeManager.captionFont)
                        .foregroundStyle(.secondary)
                    }
                    Text(isActive ? "Active" : "Tap to switch")
                        .font(themeManager.captionFont)
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if let logo = conference.squareLogo(for: colorScheme),
                   let url = URL(string: logo) {
                    KFImage(url)
                        .htDownsampled(side: 56)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 56, height: 56)
                        .cornerRadius(6)
                }
            }
        }
        // Card-style row matching ThemePickerView: cardSurface
        // background, 2pt green border + checkmark when active, soft
        // hairline border otherwise.
        .padding()
        .background(themeManager.cardSurface)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isActive ? Color.green : Color.primary.opacity(0.08),
                        lineWidth: isActive ? 2 : 0.5)
        )
        .cornerRadius(10)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}

struct ConferenceRow_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5, content: {
                Text("Conference Name")
                    .font(.title3)
                Text("Conference Dates")
                    .font(.body)
            })
            .padding()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
