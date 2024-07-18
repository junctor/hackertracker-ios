//
//  EventDetailView.swift
//
//  Created by Caleb Kinney on 3/27/23.
//

import MarkdownUI
import SwiftUI

/*
struct EventDetailView: View {
    let eventId: Int
    @FetchRequest(sortDescriptors: []) var bookmarks: FetchedResults<Bookmarks>
    @EnvironmentObject var selected: SelectedConference
    @EnvironmentObject var viewModel: InfoViewModel
    @EnvironmentObject var theme: Theme
    let dfu = DateFormatterUtility.shared
    @State var showingAlert = false
    @State var nExists = false

    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("notifyAt") var notifyAt: Int = 20

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
                            if event.tagIds.count > 0 {
                                showTags(tagIds: event.tagIds)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(15)
                }
                VStack(alignment: .leading) {
                    Markdown(event.description).padding()
                }
                if event.people.count > 0 {
                    showSpeakers(event: event)
                }
                if event.links.count > 0 {
                    Divider()
                        .(links: event.links)
                        .padding(15)
                }
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
                        MoreMenu(event: event, showingAlert: $showingAlert, notExists: $nExists)
                            .onAppear {
                                self.notificationExists()
                            }
                            .alert(isPresented: $showingAlert) {
                                Alert(
                                    title: Text(nExists ? "Remove Alert" : "Add Alert"),
                                    message: Text(nExists ? "Remove local alert for \(event.title)" : "Add local alert \(notifyAt) minutes before start of \(event.title)"),
                                    primaryButton: Alert.Button.default(Text("Yes")) {
                                        if nExists {
                                            NotificationUtility.removeNotification(event: event)
                                            nExists = false
                                        } else {
                                            let notDate = event.beginTimestamp.addingTimeInterval(Double((-notifyAt)) * 60)
                                            NotificationUtility.scheduleNotification(date: notDate, event: event)
                                            nExists = true
                                        }
                                    },
                                    secondaryButton: .cancel(Text("No"))
                                )
                            }
                    }
                }
            }
            .analyticsScreen(name: "EventDetailView")
            .navigationBarTitle(Text(""), displayMode: .inline)
        } else {
            _04View(message: "Event \(eventId) found")
        }

    }
    
    func notificationExists() {
        print("Checking for existence of notification for \(eventId)")
        UNUserNotificationCenter.current().getPendingNotificationRequests(completionHandler: { notificationRequests in
            for nr in notificationRequests where nr.identifier == "hackertracker-\(self.eventId)" {
                self.nExists = true
            }
        })
    }
}

struct showSpeakers: View {
    var event: Event
    @EnvironmentObject var viewModel: InfoViewModel
    @EnvironmentObject var theme: Theme
    @State private var collapsed = false
    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        Divider()
        VStack(alignment: .leading) {
            Button(action: {
                collapsed.toggle()
            }, label: {
                HStack {
                    Text("People")
                        .font(.headline).padding(.top)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    collapsed ? Image(systemName: "chevron.right") : Image(systemName: "chevron.down")
                }
            }).buttonStyle(BorderlessButtonStyle()).foregroundColor(.primary)
            if !collapsed {
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
        .padding(15)
    }

}
*/

struct showTags: View {
    var tagIds: [Int]
    @EnvironmentObject var viewModel: InfoViewModel
    @State private var collapsed = false
    let gridItemLayout = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(alignment: .leading) {
            if tagIds.count > 2 {
                Button(action: {
                    collapsed.toggle()
                }, label: {
                    HStack {
                        Text("Tags")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        collapsed ? Image(systemName: "chevron.right") : Image(systemName: "chevron.down")
                    }
                }).buttonStyle(BorderlessButtonStyle()).foregroundColor(.primary)
            }
            if !collapsed || tagIds.count <= 2 {
                VStack(alignment: .leading) {
                    LazyVGrid(columns: gridItemLayout, alignment: .center, spacing: 10) {
                        ForEach(tagIds, id: \.self) { tagId in
                            if let tagtype = viewModel.tagtypes.first(where: { $0.tags.contains(where: {$0.id == tagId})}), let tag = tagtype.tags.first(where: {$0.id == tagId}) {
                                VStack {
                                    HStack {
                                        Text(tag.label)
                                            .font(.subheadline)
                                            .foregroundColor(.white)
                                    }
                                }
                                .padding(5)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(UIColor(hex: tag.colorBackground ?? "#2c8f07") ?? .purple))
                                .cornerRadius(10)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .onAppear {
            if tagIds.count > 2 {
                collapsed = true
            }
        }
    }
}

/* struct EventDetailView_Previews: PreviewProvider {
    struct EventDetailPreview: View {
        // let event = InfoViewModel().events[202]

        var body: some View {
            EventDetailView(eventId: 48508).preferredColorScheme(.dark)
        }
    }

    static var previews: some View {
        EventDetailPreview()
    }
} */
