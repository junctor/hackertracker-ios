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
    var body: some View {
        HStack {
            Rectangle().fill(themeColor)
                .frame(width: 6)
                .frame(maxHeight: .infinity)
            VStack(alignment: .leading) {
                Text(speaker.name)
                    .font(.headline)
                    .foregroundColor(.white)
                if let title = speaker.title {
                    Text(title)
                        .font(.subheadline)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.gray)
                }
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
                                      name: "Speaker Name",
                                      pronouns: "they/them",
                                      twitter: "defcon",
                                      events: [])
        SpeakerRow(speaker: preview_speaker, themeColor: .purple)
    }
}
