//
//  ConferenceRow.swift
//  hackertracker
//
//  Created by Seth W Law on 6/7/22.
//

import SwiftUI

struct ConferenceRow: View {
    var conference: Conference
    var code: String

    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5, content: {
                Text(conference.name)
                    .font(themeManager.title3Font)
                if conference.startDate == conference.endDate {
                    Text(conference.endDate)
                        .font(.body)
                } else {
                    Text("\(conference.startDate) - \(conference.endDate)")
                        .font(.body)
                }
                // Polish: surface the conference timezone so users can see at
                // a glance which timezone the schedule renders in.
                if let tz = conference.timezone, !tz.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                        Text(tz)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            })
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(0)

            if conference.code == code {
                HStack(alignment: .top, spacing: 0, content: {
                    VStack(alignment: .center, spacing: 5, content: {
                        Image(systemName: "checkmark")
                    })
                })
            }
        }
        // Polish: card-style background per row so cells visually separate
        // now that we're using LazyVStack instead of List (which used to
        // provide its own row separators).
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(themeManager.cardSurface)
        .cornerRadius(12)
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
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
