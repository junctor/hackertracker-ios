//
//  SpeakerDetailView.swift
//  hackertracker
//
//  Created by Seth W Law on 6/15/22.
//

import SwiftUI
import MarkdownUI

struct SpeakerDetailView: View {
    @EnvironmentObject var viewModel: InfoViewModel
    @FetchRequest(sortDescriptors: []) var bookmarks: FetchedResults<Bookmarks>

    var id: Int

    var body: some View {
        if let speaker = viewModel.speakers.first(where: { $0.id == id }) {
            ScrollView {
                VStack(alignment: .leading) {
                    VStack(alignment: .leading) {
                        Text(speaker.name)
                            .font(.title)
                        if let title = speaker.title {
                            Text(title)
                                .font(.subheadline)
                        }
                        if let pronouns = speaker.pronouns {
                            Text("(\(pronouns))")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(15)
                    .background(Color(.systemGray6))
                    .cornerRadius(15)
                    Markdown(speaker.description).padding(.top).padding()
                    
                    if speaker.events.count > 0 {
                        Text("Events").font(.headline).padding(.top)
                        VStack {
                            ForEach(speaker.events) { event in
                                NavigationLink(destination: EventDetailView(eventId: event.id, bookmarks: bookmarks.map { $0.id })) {
                                    if let ev = viewModel.events.first(where: { $0.id == event.id }) {
                                        SpeakerEventView(event: ev, bookmarks: bookmarks.map{ $0.id })
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                        }
                        .rectangleBackground()
                    }
                }
                .padding(15)
            }
        } else {
            _04View(message: "Speaker \(id) not found")
        }
    }
}

struct SpeakerEventView: View {
    var event: Event
    var bookmarks: [Int32]
    let dfu = DateFormatterUtility.shared
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        HStack {
            Rectangle().fill(event.type.swiftuiColor)
                .frame(width: 6)
            VStack(alignment: .leading, spacing: 3) {
                Text(event.title)
                    .font(.headline)
                    .multilineTextAlignment(.leading)
                Text(dfu.shortDayMonthDayTimeOfWeekFormatter.string(from: event.beginTimestamp))
                    .font(.subheadline)
                Text(event.location.name).font(.caption2)
                VStack {
                    HStack {
                        Circle().foregroundColor(event.type.swiftuiColor)
                            .frame(width: 8, height: 8, alignment: .center)
                        Text(event.type.name).font(.caption)
                        Spacer()
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity)
            }
            .frame(alignment: .leading)

            HStack(alignment: .center) {
                Button {
                    bookmarkAction()
                } label: {
                    Image(systemName: bookmarks.contains(Int32(event.id)) ? "bookmark.fill" : "bookmark")
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    func bookmarkAction() {
        if bookmarks.contains(Int32(event.id)) {
            print("SpeakerDetailView: Removing Bookmark \(event.id)")
            BookmarkUtility.deleteBookmark(context: viewContext, id: event.id)
        } else {
            print("SpeakerDetailView: Adding Bookmark \(event.id)")
            BookmarkUtility.addBookmark(context: viewContext, id: event.id)
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
