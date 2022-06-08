//
//  EventRow.swift
//  hackertracker
//
//  Created by Seth W Law on 6/7/22.
//

import SwiftUI

struct EventRow: View {
    var event: Event
    let dfu = DateFormatterUtility.shared
    
    var body: some View {
        HStack {
            Color.accentColor.frame(width: 5, height: 60)
            VStack (alignment: .leading, spacing: 0, content: {
                Text(dfu.shortDayOfMonthFormatter.string(from: event.begin))
                    .font(.caption)
                    .dynamicTypeSize(.small)
                Text(dfu.hourMinuteTimeFormatter.string(from: event.begin))
                    .font(.body)
                    .dynamicTypeSize(.small)
                Text(dfu.timezoneFormatter.string(from: event.begin))
                    .font(.caption)
                    .dynamicTypeSize(.xSmall)
                
            })
            .padding()
            
            VStack (alignment: .leading, spacing: 0, content: {
                Text(event.title)
                    .font(.title3)
                    .dynamicTypeSize(.medium)
                Text("Speaker Name")
                    .font(.body)
                    .dynamicTypeSize(.small)
                Text(event.location)
                    .font(.caption)
                    .dynamicTypeSize(.xSmall)
            })
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
    }
}

struct EventRow_Previews: PreviewProvider {
    static var previews: some View {
        EventRow(event: events[1])
    }
}
