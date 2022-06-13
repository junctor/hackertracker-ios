//
//  ConferenceRow.swift
//  hackertracker
//
//  Created by Seth W Law on 6/7/22.
//

import SwiftUI

struct ConferenceRow: View {
    var conference: Conference
    let dfu = DateFormatterUtility.shared
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5, content: {
                Text(conference.name)
                    .font(.title3)
                Text("\(conference.startDate) - \(conference.endDate)")
                    .font(.body)
            })
            .padding()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
