//
//  ConferenceRow.swift
//  hackertracker
//
//  Created by Seth W Law on 6/7/22.
//

import SwiftUI

struct ConferenceRow: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5, content: {
                Text("Conference Name")
                    .font(.title3)
                    .dynamicTypeSize(.medium)
                Text("Conference Dates")
                    .font(.body)
                    .dynamicTypeSize(.small)
            })
            .padding()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ConferenceRow_Previews: PreviewProvider {
    static var previews: some View {
        ConferenceRow()
    }
}
