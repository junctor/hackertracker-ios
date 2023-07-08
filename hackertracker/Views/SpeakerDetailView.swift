//
//  SpeakerDetailView.swift
//  hackertracker
//
//  Created by Seth W Law on 6/15/22.
//

import SwiftUI
import MarkdownUI
import Kingfisher

struct SpeakerDetailView: View {
    @EnvironmentObject var viewModel: InfoViewModel
    @Environment(\.openURL) private var openURL
    @EnvironmentObject var theme: Theme

    var id: Int

    var body: some View {
        if let speaker = viewModel.speakers.first(where: { $0.id == id }) {
            ScrollView {
                VStack(alignment: .leading) {
                    VStack(alignment: .leading) {
                        Text(speaker.name)
                            .font(.title)
                        if let pronouns = speaker.pronouns {
                            Text("(\(pronouns))")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        if let affiliations = speaker.affiliations {
                            showAffiliations(affiliations: affiliations)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(15)
                    .background(Color(.systemGray6))
                    .cornerRadius(15)
                    if let media = speaker.media, media.count > 0 {
                        HStack {
                            ForEach(media, id: \.assetId) { m in
                                if let url = URL(string: m.url) {
                                    KFImage(url)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 150)
                                        .cornerRadius(15)
                                }
                            }
                        }
                    }
                    
                    Markdown(speaker.description)
                    
                    Divider()
                    if speaker.events.count > 0 {
                        showEvents(events: speaker.events)
                    }
                    Divider()
                    if speaker.links.count > 0 {
                        showLinks(links: speaker.links)
                    }
                }
                .padding(15)
            }
        } else {
            _04View(message: "Speaker \(id) not found")
        }
    }
}

struct showLinks: View {
    var links: [SpeakerLink]
    @Environment(\.openURL) private var openURL
    @State private var collapsed = false
    @EnvironmentObject var theme: Theme

    var body: some View {
        VStack(alignment: .leading) {
            Button(action: {
                collapsed.toggle()
            }, label: {
                HStack {
                    Text("Links")
                        .font(.headline).padding(.top)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    collapsed ? Image(systemName: "chevron.right") : Image(systemName: "chevron.down")
                }
            }).buttonStyle(BorderlessButtonStyle()).foregroundColor(.white)
            if !collapsed {
                VStack(alignment: .leading) {
                    ForEach(links, id: \.title) { link in
                        if let url = URL(string: link.url) {
                            Button {
                                openURL(url)
                            } label: {
                                if link.title != "" {
                                    Label(link.title, systemImage: "arrow.up.right.square")
                                } else {
                                    Label(link.url, systemImage: "link")
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(15)
                            .background(theme.carousel())
                            .cornerRadius(15)
                            
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

struct showEvents: View {
    var events: [SpeakerEvent]
    @FetchRequest(sortDescriptors: []) var bookmarks: FetchedResults<Bookmarks>
    @EnvironmentObject var viewModel: InfoViewModel
    @State private var collapsed = false
    
    var body: some View {
        VStack(alignment: .leading) {
            Button(action: {
                collapsed.toggle()
            }, label: {
                HStack {
                    Text("Events")
                        .font(.headline).padding(.top)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    collapsed ? Image(systemName: "chevron.right") : Image(systemName: "chevron.down")
                }
            }).buttonStyle(BorderlessButtonStyle()).foregroundColor(.white)
            if !collapsed {
                VStack {
                    ForEach(events) { event in
                        NavigationLink(destination: EventDetailView(eventId: event.id, bookmarks: bookmarks.map { $0.id })) {
                            if let ev = viewModel.events.first(where: { $0.id == event.id }) {
                                SpeakerEventView(event: ev, bookmarks: bookmarks.map { $0.id })
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct showAffiliations: View {
    let affiliations: [SpeakerAffiliation]
    @State private var collapsed = true

    var body: some View {
        Divider()
        ForEach(affiliations, id: \.organization) { affiliation in
            VStack(alignment: .leading) {
                /*@START_MENU_TOKEN@*/Text(affiliation.organization)/*@END_MENU_TOKEN@*/
                if affiliation.title != "" {
                    Text(affiliation.title)
                        .font(.subheadline)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
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
