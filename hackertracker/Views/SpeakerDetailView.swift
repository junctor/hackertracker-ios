//
//  SpeakerDetailView.swift
//  hackertracker
//
//  Created by Seth W Law on 6/15/22.
//

import SwiftUI

struct SpeakerDetailView: View {
    @ObservedObject private var viewModel = SpeakerViewModel()
    var id: Int

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text(viewModel.speaker?.name ?? viewModel.speaker?.name ?? "").font(.largeTitle)
                Text(viewModel.speaker?.title ?? "")
                Divider()
                Text(viewModel.speaker?.description ?? "").padding(.top).padding()

                if !(viewModel.speaker?.events.isEmpty ?? false) {
                    Text("Events").font(.headline).padding(.top)
                    VStack(alignment: .leading) {
                        ForEach(viewModel.speaker?.events ?? []) { event in
                            SpeakerEventsView(event: event, bookmarks: [])
                        }
                    }
                    .rectangleBackground()
                }
            }
            Spacer()
        }
        .onAppear {
            viewModel.fetchData(speakerId: String(id))
        }
    }
}

struct SpeakerEventsView: View {
    var event: SpeakerEvent
    @State var bookmarks: [Int]

    var body: some View {
        HStack {
            Rectangle().fill(Color.purple).frame(width: 10)
            VStack(alignment: .leading) {
                Text(event.title ?? "").fontWeight(.bold)
            }
        }
    }
}

struct SpeakerDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SpeakerDetailView(id: 1).preferredColorScheme(.dark)
        }
    }
}
