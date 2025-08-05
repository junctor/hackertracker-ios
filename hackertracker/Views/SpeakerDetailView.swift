//
//  SpeakerDetailView.swift
//  hackertracker
//
//  Created by Seth W Law on 6/15/22.
//

import SwiftUI
import MarkdownUI
import Kingfisher
import FirebaseAnalytics

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
                        if let affiliations = speaker.affiliations, affiliations.count > 0 {
                            showAffiliations(affiliations: affiliations)
                        }
                    }
                    .foregroundColor(.primary)
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
                    
                    if speaker.eventIds.count > 0 {
                        Divider()
                        showEvents(eventIds: speaker.eventIds)
                    }
                    if speaker.links.count > 0 {
                        Divider()
                        showSpeakerLinks(links: speaker.links)
                    }
                }
                .padding(15)
            }
            .navigationBarTitle(Text(""), displayMode: .inline)
            .analyticsScreen(name: "SpeakerDetailView")
        } else {
            _04View(message: "Speaker \(id) not found")
        }
    }
}

struct showSpeakerLinks: View {
    var links: [SpeakerLink]
    @Environment(\.openURL) private var openURL
    @State private var collapsed = false
    @EnvironmentObject var theme: Theme
    @AppStorage("colorMode") var colorMode: Bool = false

    var body: some View {
        VStack(alignment: .leading) {
            Button(action: {
                collapsed.toggle()
            }, label: {
                HStack {
                    Text("Links")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if collapsed {
                        Text("Show")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    } else {
                        Text("Hide")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                        Image(systemName: "chevron.down")
                            .foregroundColor(.secondary)
                    }                }
            }).buttonStyle(BorderlessButtonStyle()).foregroundColor(.primary)
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
                            .foregroundColor(colorMode ? .white : .primary)
                            .frame(maxWidth: .infinity)
                            .padding(15)
                            .background(colorMode ? theme.carousel(): Color(.systemGray6))
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
    var eventIds: [Int]
    var title: String?
    @FetchRequest(sortDescriptors: []) var bookmarks: FetchedResults<Bookmarks>
    @EnvironmentObject var viewModel: InfoViewModel
    @State private var collapsed = false
    @State private var myEvents: [Event] = []
    
    var body: some View {
        VStack(alignment: .leading) {
            Button(action: {
                collapsed.toggle()
            }, label: {
                HStack {
                    Text(title ?? "Schedule")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if collapsed {
                        Text("Show")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    } else {
                        Text("Hide")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                        Image(systemName: "chevron.down")
                            .foregroundColor(.secondary)
                    }                }
            }).buttonStyle(BorderlessButtonStyle()).foregroundColor(.primary)
            if !collapsed {
                VStack {
                    ForEach(myEvents) { event in
                        //if let ev = viewModel.events.first(where: {$0.id == eventId}) {
                            NavigationLink(destination: ContentDetailView(contentId: event.contentId)) {
                                    SpeakerEventView(event: event)
                                        .foregroundColor(.primary)
                            }
                        //}
                    }
                }
            }
        }
        .task {
            sortEvents()
        }
    }
    
    func sortEvents() {
        var unsortedEvents: [Event] = []
        for e in eventIds {
            if let events = viewModel.events.first(where: {$0.id == e}) {
                unsortedEvents.append(events)
            }
        }
        myEvents = unsortedEvents.sorted(by:{ $0.beginTimestamp < $1.endTimestamp })
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
    @FetchRequest(sortDescriptors: []) var bookmarks: FetchedResults<Bookmarks>
    let dfu = DateFormatterUtility.shared
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var viewModel: InfoViewModel
    @AppStorage("notifyAt") var notifyAt: Int = 20

    var body: some View {
        HStack {
            Rectangle().fill(getEventTagColorBackground(id: event.tagIds[0]))
                .frame(width: 6)
            VStack(alignment: .leading, spacing: 3) {
                Text(event.title)
                    .font(.headline)
                    .multilineTextAlignment(.leading)
                Text(dfu.shortDayMonthDayTimeOfWeekFormatter.string(from: event.beginTimestamp))
                    .font(.subheadline)
                if let l = viewModel.locations.first(where: {$0.id == event.locationId}) {
                    Text(l.name).font(.caption2)
                }
                // if let tagtype = viewModel.tagtypes.first(where: { $0.tags.contains(where: {$0.id == tagId})}), let tag = tagtype.tags.first(where: {$0.id == tagId})
                if let tagType = viewModel.tagtypes.first(where: { $0.tags.contains(where: {$0.id == event.tagIds[0]})}), let tag = tagType.tags.first(where: {$0.id == event.tagIds[0]}) {
                    VStack {
                        HStack {
                            Circle().foregroundColor(Color(UIColor(hex: tag.colorBackground ?? "#2c8f07") ?? .purple))
                                .frame(width: 8, height: 8, alignment: .center)
                            
                            Text(tag.label).font(.caption)
                            Spacer()
                        }
                    }
                    .frame(minWidth: 0, maxWidth: .infinity)
                }
            }
            .frame(alignment: .leading)

            HStack(alignment: .center) {
                Button {
                    bookmarkAction()
                } label: {
                    Image(systemName: bookmarks.map({$0.id}).contains(Int32(event.id)) ? "bookmark.fill" : "bookmark")
                        .foregroundColor((bookmarks.map({$0.id}).contains(Int32(event.id)) && viewModel.bookmarkConflicts(eventId: event.id, bookmarks: bookmarks.map{Int($0.id)} )) ? ThemeColors.red : .primary)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    func bookmarkAction() {
        if bookmarks.map({$0.id}).contains(Int32(event.id)) {
            BookmarkUtility.deleteBookmark(context: viewContext, id: event.id)
            NotificationUtility.removeNotification(id: event.id)
        } else {
            BookmarkUtility.addBookmark(context: viewContext, id: event.id)
            let notDate = event.beginTimestamp.addingTimeInterval(Double((-notifyAt)) * 60)
            NotificationUtility.scheduleNotification(date: notDate, id: event.id, title: event.title, location: viewModel.locations.first(where: {$0.id == event.locationId})?.name ?? "unknown")
        }
    }
    
    func getEventTagColorBackground(id: Int) -> Color {
        if let tagtype = viewModel.tagtypes.first(where: {$0.tags.contains(where: {$0.id == id})}),
           let tag = tagtype.tags.first(where: { $0.id == id}),
           let colorHex = tag.colorBackground, let uicolor = UIColor(hex: colorHex) {
            return Color(uiColor: uicolor)
        }
        return .purple
    }
}

struct SpeakerDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SpeakerDetailView(id: 1).preferredColorScheme(.dark)
        }
    }
}
