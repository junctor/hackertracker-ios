//
//  EventDetailView.swift
//  hackertracker
//
//  Created by Seth W Law on 6/14/22.
//

import SwiftUI

struct EventDetailView: View {
    @ObservedObject private var viewModel = EventViewModel()
    var id: Int

    @EnvironmentObject var bookmarks: oBookmarks
    var theme = Theme()
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        ScrollView {
            if let event = viewModel.event {
                VStack(alignment: .center) {
                    Text(event.title).font(.largeTitle).bold()
                    VStack(alignment: .leading) {
                        HStack {
                            Circle().foregroundColor(event.type.swiftuiColor)
                                .frame(width: 15, height: 15, alignment: .center)
                            Text(event.type.name).font(.subheadline).bold()
                        }
                        .padding(.vertical)
                        HStack {
                            Image(systemName: "clock")
                            Text("\(event.beginTimestamp.formatted(.dateTime.month().day().hour().minute())) - \(event.endTimestamp.formatted(.dateTime.month().day().hour().minute()))")
                                .font(.subheadline).bold()
                        }.padding(.bottom)
                        HStack {
                            Image(systemName: "map")
                            Text(event.location.name).font(.subheadline).bold()
                        }.padding(.bottom)
                        Text(event.description).padding(.horizontal)
                        Spacer()
                        if event.speakers.count > 0 {
                            VStack(alignment: .leading) {
                                Text("^[\(event.speakers.count) Speaker](inflect: true)").font(.headline)
                                VStack(alignment: .leading) {
                                    ForEach(event.speakers, id: \.id) { speaker in
                                        HStack {
                                            Rectangle().fill(theme.carousel())
                                                .frame(width: 5)

                                            Text(speaker.name)
                                        }
                                    }
                                }
                                Spacer()
                            }.padding(.horizontal)
                        }
                    }
                    .padding(.horizontal)
                }
            } else {
                _04View(message: "Event not found")
            }
        }
        .toolbar {
            Button {
                if let event = viewModel.event {
                    if bookmarks.bookmarks.contains(event.id) {
                        BookmarkUtility.deleteBookmark(context: viewContext, id: event.id)
                    } else {
                        BookmarkUtility.addBookmark(context: viewContext, id: event.id)
                        // bookmarks.bookmarks.append(event.id)
                    }
                }
            } label: {
                if let event = viewModel.event {
                    Image(systemName: bookmarks.bookmarks.contains(event.id) ? "star.fill" : "star")
                }
            }
        }
        /* .navigationBarItems(trailing: bookmarks.bookmarks.contains(id) ? Image(systemName: "star.fill").onTapGesture {
             BookmarkUtility.deleteBookmark(context: viewContext, id: id)
             if let index = bookmarks.bookmarks.firstIndex(of: id) {
                 bookmarks.bookmarks.remove(at: index)
             }
         } : Image(systemName: "star").onTapGesture {
             BookmarkUtility.addBookmark(context: viewContext, id: id)
             bookmarks.bookmarks.append(id)
         }) */
        .onAppear {
            viewModel.fetchData(eventId: String(id))
        }
    }
}

struct EventDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            // EventDetailView()
        }
    }
}
