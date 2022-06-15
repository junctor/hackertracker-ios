//
//  EventDetailView.swift
//  hackertracker
//
//  Created by Seth W Law on 6/14/22.
//

import SwiftUI

struct EventDetailView: View {
    var event: Event
    @State var bookmarks: [Int]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0, content: {
            Text(event.title)
                .font(.title)
            Text(event.description)
                .font(.body)
        })
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(0)
        
    }
}

struct EventDetailView_Previews: PreviewProvider {
    static var previews: some View {
        Text("Event Detail View")
    }
}
