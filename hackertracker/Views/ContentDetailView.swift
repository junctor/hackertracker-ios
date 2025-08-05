//
//  ContentDetailView.swift
//  hackertracker
//
//  Created by Seth Law on 6/23/24.
//

import Kingfisher
import MarkdownUI
import SwiftUI

struct ContentDetailView: View {
    let contentId: Int
    @State private var showFeedback: Bool = false
    // @State private var showFeedbackButton = true
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @EnvironmentObject var viewModel: InfoViewModel
    @FetchRequest(sortDescriptors: []) var feedbacks: FetchedResults<Feedbacks>
    @Environment(\.managedObjectContext) private var viewContext
    let dfu = DateFormatterUtility.shared
    let currentTime = Date()

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        if let item = viewModel.content.first(where: { $0.id == contentId }) {
            ScrollView {
                VStack(alignment: .leading) {
                    VStack(alignment: .center) {
                        Text(item.title).font(.largeTitle).bold()
                        if !item.sessions.isEmpty {
                            showSessions(item: item)
                        }
                        
                        if !item.tagIds.isEmpty {
                            VStack(alignment: .leading) {
                                showTags(tagIds: item.tagIds)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(15)
                }
                VStack(alignment: .leading) {
                    Markdown(item.description)
                        .textSelection(.enabled)
                        .padding()
                }
                if item.media.count > 0 {
                    showMedia(media: item.media)
                        .padding(15)
                }
                if !item.people.isEmpty {
                    showPeople(content: item)
                }
                if !item.links.isEmpty {
                    Divider()
                    showLinks(links: item.links)
                        .padding(15)
                }
                if let relatedIds = item.relatedIds, !relatedIds.isEmpty, relatedIds.count > 0 {
                    Divider()
                    showRelated(eventIds: relatedIds)
                        .padding(15)
                }
                if alertMessage != "" {
                    VStack(alignment: .center) {
                        Text(alertMessage)
                    }
                    .padding(15)
                    Divider()
                }
                if let fe = item.feedbackEnableTimestamp, let fd = item.feedbackDisableTimestamp, currentTime > fe, currentTime < fd, !feedbacks.map({$0.id}).contains(Int32(item.id)) {
                    showFeedbackButton(showFeedback: $showFeedback)
                        .padding(15)
                }
                
            }
            .analyticsScreen(name: "ContentDetailView")
            .navigationBarTitle(Text(""), displayMode: .inline)
            .fullScreenCover(isPresented: $showFeedback) {
                if let form = viewModel.feedbackForms.first(where: {$0.id == item.feedbackFormId}) {
                    FeedbackFormView(showFeedback: $showFeedback, item: item, form: form, showAlert: $showAlert, alertMessage: $alertMessage)
                }
            }
            .onAppear() {
                print("ContentDetailView Loading \(item.id) - \(item.title)")
            }
            /* .alert(isPresented: $showAlert) {
                Alert(title: Text("Submit Feedback"), message: Text(alertMessage), dismissButton: .default(Text("OK")) {
                    FeedbackUtility.addFeedback(context: viewContext, id: item.id)
                })
            } */
        } else {
            _04View(message: "Content \(contentId) not found")
        }

    }
}

struct showFeedbackButton: View {
    @Binding var showFeedback: Bool
    @EnvironmentObject var viewModel: InfoViewModel
    @EnvironmentObject var theme: Theme
    @AppStorage("colorMode") var colorMode: Bool = false

    var body: some View {
        VStack {
            Button {
                showFeedback = true
            } label: {
                Label("Submit Feedback", systemImage: "square.and.pencil")
            }
            .foregroundColor(colorMode ? .white : .primary)
            .frame(maxWidth: .infinity)
            .padding(15)
            .background(colorMode ? theme.carousel() : Color(.systemGray6))
            .cornerRadius(15)
        }
    }
}

struct showMedia: View {
    var media: [Media]
    
    var body: some View {
        VStack(alignment: .leading) {
                HStack {
                    ForEach(media, id: \.assetId) { m in
                        if let url = URL(string: m.url) {
                            KFImage(url)
                                .resizable()
                                .scaledToFit()
                                .aspectRatio(contentMode: .fit)
                                .cornerRadius(15)
                                .padding(.leading, 10)
                                .padding(.trailing, 10)
                        }
                    }
                }
            //}
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
}

struct showSessions: View {
    var item: Content
    @State var showAddContentModal = false
    @State private var collapsed = false
    // @State var showingAlert: Bool = false
    // @State var notExists: Bool = false

    
    var body: some View {
        VStack(alignment: .leading) {
            if item.sessions.count > 1 {
                Button(action: {
                    collapsed.toggle()
                }, label: {
                    HStack {
                        Text("Sessions")
                            .font(.subheadline)
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
                        }
                    }
                }).buttonStyle(BorderlessButtonStyle()).foregroundColor(.primary)
            }
            if !collapsed || item.sessions.count == 1 {
                ForEach(item.sessions.sorted { $0.beginTimestamp < $1.beginTimestamp }) { s in
                    showSessionRow(item: item, s: s, showAddContentModal: $showAddContentModal)
                }
            }
        }
    }
}

struct showSessionRow: View {
    var item: Content
    var s: Session
    @Binding var showAddContentModal: Bool
    let dfu = DateFormatterUtility.shared
    
    @State var notExists: Bool = false
    @AppStorage("notifyAt") var notifyAt: Int = 20
    @AppStorage("show24hourtime") var show24hourtime: Bool = true
    @EnvironmentObject var viewModel: InfoViewModel
    
    @FetchRequest(sortDescriptors: []) var bookmarks: FetchedResults<Bookmarks>
    @Environment(\.managedObjectContext) private var viewContext
    
    func bookmarkAction(id: Int) {
        if bookmarks.map({$0.id}).contains(Int32(id)) {
            BookmarkUtility.deleteBookmark(context: viewContext, id: id)
            if notExists {
                NotificationUtility.removeNotification(id: id)
                notExists.toggle()
            }
        } else {
            BookmarkUtility.addBookmark(context: viewContext, id: id)
            if !notExists {
                let notDate = s.beginTimestamp.addingTimeInterval(Double((-notifyAt)) * 60)
                NotificationUtility.scheduleNotification(date: notDate, id: s.id, title: item.title, location: viewModel.locations.first(where: {$0.id == s.locationId})?.name ?? "unknown")
                notExists.toggle()
            } else {
            }
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    Button {
                        showAddContentModal.toggle()
                    } label: {
                        Image(systemName: "clock")
                    }
                    if show24hourtime {
                        if s.beginTimestamp != s.endTimestamp {
                            Text("\(dfu.shortDayMonthDayTimeOfWeekFormatter.string(from: s.beginTimestamp))-\(dfu.hourMinuteTimeFormatter.string(from: s.endTimestamp))")
                                .font(.subheadline)
                        } else {
                            Text("\(dfu.shortDayMonthDayTimeOfWeekFormatter.string(from: s.beginTimestamp))")
                                .font(.subheadline)
                        }
                    } else {
                        if s.beginTimestamp != s.endTimestamp {
                            Text("\(dfu.shortDayMonthDay12HourOfWeekFormatter.string(from: s.beginTimestamp))-\(dfu.hourMinute12TimeFormatter.string(from: s.endTimestamp))")
                                .font(.subheadline)
                        } else {
                            Text("\(dfu.shortDayMonthDay12HourOfWeekFormatter.string(from: s.beginTimestamp))")
                                .font(.subheadline)
                        }
                    }
                }
                .fullScreenCover(isPresented: $showAddContentModal) {
                    AddContent(content: item, session: s)
                }
                HStack {
                    Image(systemName: "map")
                    Text(viewModel.locations.first(where: {$0.id == s.locationId})?.name ?? "unkown").font(.caption)
                }
            }
            .padding(.leading, 5)
            .padding(.trailing, 5)
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity, alignment: .leading)
            VStack(alignment: .trailing) {
                HStack(alignment: .center) {
                    Button {
                        bookmarkAction(id: s.id)
                    } label: {
                        Image(systemName: bookmarks.map{$0.id}.contains(Int32(s.id)) ? "bookmark.fill" : "bookmark")
                            .foregroundColor((bookmarks.map({$0.id}).contains(Int32(s.id)) && viewModel.bookmarkConflicts(eventId: s.id, bookmarks: bookmarks.map{Int($0.id)} )) ? ThemeColors.red : .primary)
                    }
                    MoreContentMenu(content: item, session: s, notExists: $notExists)
                }
            }
        }
        .task {
            Task {
                notExists = await NotificationUtility.notificationExists(id: s.id)
            }
        }
        .padding(.leading, 5)
        .padding(.trailing, 5)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .cornerRadius(10)
        .padding(.bottom, 5)
    }
}

struct MoreView: View {
    var body: some View {
        HStack {
            Text("More")
            Image(systemName: "chevron.right")
        }
    }
}

struct showRelated: View {
    var eventIds: [Int]
    @FetchRequest(sortDescriptors: []) var bookmarks: FetchedResults<Bookmarks>
    @EnvironmentObject var viewModel: InfoViewModel
    @State private var collapsed = true
    
    var body: some View {
        VStack(alignment: .leading) {
            Button(action: {
                collapsed.toggle()
            }, label: {
                HStack {
                    Text("Related Content")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if collapsed {
                        Text("More")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    } else {
                        Text("Less")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                        Image(systemName: "chevron.down")
                            .foregroundColor(.secondary)
                    }
                }
            }).buttonStyle(BorderlessButtonStyle()).foregroundColor(.primary)
            if !collapsed {
                VStack {
                    ForEach(eventIds, id: \.self) { eventId in
                        if let c = viewModel.content.first(where: {$0.id == eventId}) {
                            NavigationLink(destination: ContentDetailView(contentId: c.id)) {
                                ContentCell(content: c, bookmarks: bookmarks.map { $0.id }, showDay: true)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            } else {
                VStack {
                        let eventId = eventIds[0]
                        if let c = viewModel.content.first(where: {$0.id == eventId}) {
                            NavigationLink(destination: ContentDetailView(contentId: c.id)) {
                                ContentCell(content: c, bookmarks: bookmarks.map { $0.id }, showDay: true)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                }
            }
        }
    }
}

struct showPeople: View {
    var content: Content
    @EnvironmentObject var viewModel: InfoViewModel
    @EnvironmentObject var theme: Theme
    @State private var collapsed = false
    @AppStorage("colorMode") var colorMode: Bool = false
    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        Divider()
        VStack(alignment: .leading) {
            Button(action: {
                collapsed.toggle()
            }, label: {
                HStack {
                    Text("People")
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
                    }
                    //collapsed ? Image(systemName: "chevron.right") : Image(systemName: "chevron.down")
                }
            }).buttonStyle(BorderlessButtonStyle()).foregroundColor(.primary)
            if !collapsed {
                let people = content.people.sorted { $0.sortOrder < $1.sortOrder }
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
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .padding(15)
                                .background(colorMode ? theme.carousel(): Color(.systemGray6))
                                .cornerRadius(15)
                            }
                        }
                    }
                } else if let speaker = viewModel.speakers.first(where: {$0.id == content.people[0].id}) {
                    HStack {
                        NavigationLink(destination: SpeakerDetailView(id: speaker.id)) {
                            VStack {
                                Text(speaker.name)
                                if let tagtype = viewModel.tagtypes.first(where: {$0.category == "content-person"}), let tag = tagtype.tags.first(where: {$0.id == content.people[0].tagId}) {
                                    Text(tag.label).font(.caption)
                                }
                            }
                        }
                    }
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(15)
                    .background(colorMode ? theme.carousel(): Color(.systemGray6))
                    .cornerRadius(15)
                }
            }
        }
        .padding(15)
    }

}



struct ContentDetailPreviews: PreviewProvider {
    struct ContentDetailPreview: View {
        // let event = InfoViewModel().events[202]

        var body: some View {
            ContentDetailView(contentId: 48508).preferredColorScheme(.dark)
        }
    }

    static var previews: some View {
        ContentDetailPreview()
    }
}

