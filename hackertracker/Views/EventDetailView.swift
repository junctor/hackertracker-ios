//
//  EventDetailView.swift
//
//  Created by Caleb Kinney on 3/27/23.
//

import MarkdownUI
import SwiftUI

struct EventDetailView: View {
    let eventId: Int
    @FetchRequest(sortDescriptors: []) var bookmarks: FetchedResults<Bookmarks>
    @EnvironmentObject var selected: SelectedConference
    @EnvironmentObject var viewModel: InfoViewModel
    @EnvironmentObject var theme: Theme
    let dfu = DateFormatterUtility.shared

    @Environment(\.managedObjectContext) private var viewContext

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        if let event = viewModel.events.first(where: { $0.id == eventId }) {
            ScrollView {
                VStack(alignment: .leading) {
                    VStack(alignment: .center) {
                        Text(event.title).font(.largeTitle).bold()
                        VStack(alignment: .leading) {
                            HStack {
                                Circle().foregroundColor(event.type.swiftuiColor)
                                   .frame(width: 15, height: 15, alignment: .center)
                                Text(event.type.name).font(.subheadline).bold()
                            }
                            .padding(.leading, 10)
                            .padding(.trailing, 5)
                            .padding(.vertical, 5)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.background)
                            .cornerRadius(10)
                            .padding(.bottom, 5)
                            HStack {
                                Image(systemName: "clock")
                                Text("\(dfu.shortDayMonthDayTimeOfWeekFormatter.string(from: event.beginTimestamp)) - \(dfu.shortDayMonthDayTimeOfWeekFormatter.string(from: event.endTimestamp))")
                                   .font(.subheadline).bold()
                            }
                            .padding(.leading, 10)
                            .padding(.trailing, 5)
                            .padding(.vertical, 5)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.background)
                            .cornerRadius(10)
                            .padding(.bottom, 5)
                            HStack {
                                Image(systemName: "map")
                                Text(event.location.name).font(.subheadline).bold()
                            }
                            .padding(.leading, 10)
                            .padding(.trailing, 5)
                            .padding(.vertical, 5)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.background)
                            .cornerRadius(10)
                            .padding(.bottom, 5)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(15)
                }
                VStack(alignment: .leading) {
                    Markdown(event.description).padding()
                }
                VStack {
                    if event.people.count > 0 {
                        let people = event.people.sorted { $0.sortOrder < $1.sortOrder }
                        if people.count > 1 {
                            LazyVGrid(columns: columns, spacing: 20) {
                                ForEach(people, id: \.id) { person in
                                    if let speaker = viewModel.speakers.first(where: {$0.id == person.id}) {
                                        HStack {
                                            NavigationLink(destination: SpeakerDetailView(id: speaker.id)) {
                                                VStack {
                                                    Text(speaker.name)
                                                    if let tagtype = viewModel.tagtypes.first(where: {$0.category == "content-person"}), let tag = tagtype.tags.first(where: {$0.id == person.tagId}) {
                                                        Text(tag.label).font(.caption)
                                                    }
                                                }
                                            }
                                        }
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .padding(15)
                                        .background(theme.carousel().gradient)
                                        .cornerRadius(15)
                                    }
                                }
                            }
                        } else {
                            HStack {
                                NavigationLink(destination: SpeakerDetailView(id: event.speakers[0].id)) {
                                    VStack {
                                        Text(event.speakers[0].name)
                                        if let tagtype = viewModel.tagtypes.first(where: {$0.category == "content-person"}), let tag = tagtype.tags.first(where: {$0.id == people[0].tagId}) {
                                            Text(tag.label).font(.caption)
                                        }
                                    }
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(15)
                            .background(theme.carousel().gradient)
                            .cornerRadius(15)
                        }
                    }
                }
                .padding(.horizontal, 15)
            }
            .toolbar {
                ToolbarItemGroup {
                    if let event = viewModel.events.first(where: { $0.id == eventId }) {
                        Button {
                            if bookmarks.map({ $0.id }).contains(Int32(event.id)) {
                                BookmarkUtility.deleteBookmark(context: viewContext, id: event.id)
                            } else {
                                BookmarkUtility.addBookmark(context: viewContext, id: event.id)
                            }
                        } label: {
                            if let event = viewModel.events.first(where: { $0.id == eventId }) {
                                Image(systemName: bookmarks.map({ $0.id }).contains(Int32(event.id)) ? "bookmark.fill" : "bookmark")
                            }
                        }
                        MoreMenu(event: event)
                    }
                }
            }
            .navigationBarTitle(Text(""), displayMode: .inline)
            .toolbar(.hidden, for: .tabBar)
        } else {
            _04View(message: "Event \(eventId) found")
        }

    }
}

struct EventDetailView_Previews: PreviewProvider {
    struct EventDetailPreview: View {
        // let event = InfoViewModel().events[202]

        var body: some View {
            EventDetailView(eventId: 48508).preferredColorScheme(.dark)
        }
    }

    static var previews: some View {
        EventDetailPreview()
    }
}
