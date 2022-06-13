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
                Text(dfu.shortDayOfMonthFormatter.string(from: event.beginTimestamp))
                    .font(.caption)
                Text(dfu.hourMinuteTimeFormatter.string(from: event.beginTimestamp))
                    .font(.body)
                Text(dfu.timezoneFormatter.string(from: event.beginTimestamp))
                    .font(.caption)
                
            })
            .padding()
            
            VStack (alignment: .leading, spacing: 0, content: {
                Text(event.title)
                    .font(.title3)
                Text("Speaker Name")
                    .font(.body)
                Text(event.location.name)
                    .font(.caption)
            })
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(0)
            
            HStack(alignment: .top, spacing: 0, content: {
                VStack(alignment: .center, spacing: 5, content: {
                    Image(systemName: "star")
                })
            })
        }
    }
}

struct EventRow_Previews: PreviewProvider {
    static var previews: some View {
        Text("Preview blah")
    }
}
