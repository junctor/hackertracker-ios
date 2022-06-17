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

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5, content: {
                Text(conference.name)
                    .font(.title3)
                Text("\(conference.startDate) - \(conference.endDate)")
                    .font(.body)
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
