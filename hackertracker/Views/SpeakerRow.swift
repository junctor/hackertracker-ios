//
//  SpeakerRow.swift
//  hackertracker
//
//  Created by Seth W Law on 6/15/22.
//

import SwiftUI

struct SpeakerRow: View {
    var speaker: Speaker
    var body: some View {
        HStack {
            Rectangle().fill(Color.yellow).frame(width: 10, height: .infinity)
            VStack(alignment: .leading) {
                Text(speaker.name).fontWeight(.bold)
                Text(speaker.title ?? "Hacker")
            }
        }
    }
}

struct SpeakerRow_Previews: PreviewProvider {
    
    static var previews: some View {
        let preview_speaker: Speaker = Speaker(id: 123123,
                                               conferenceName: "DEF CON 30",
                                               description: "Description",
                                               link: "https://twitter.com/defcon",
                                               name: "Speaker Name",
                                               twitter: "defcon",
                                               events: [] )
        SpeakerRow(speaker: preview_speaker)
    }
}
