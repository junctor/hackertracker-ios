//
//  ContentDetailView.swift
//  hackertracker
//
//  Created by Seth Law on 6/23/24.
//

import SwiftUI

import MarkdownUI
import SwiftUI

struct ContentDetailView: View {
    let contentId: Int
    let sessionId: Int = 0
    @FetchRequest(sortDescriptors: []) var bookmarks: FetchedResults<Bookmarks>
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
    
    func bookmarkAction(id: Int) {
        if bookmarks.map({$0.id}).contains(Int32(id)) {
            print("ContentDetailView: Removing Bookmark \(id)")
            BookmarkUtility.deleteBookmark(context: viewContext, id: id)
        } else {
            print("ContentDetailView: Adding Bookmark \(id)")
            BookmarkUtility.addBookmark(context: viewContext, id: id)
        }
    }

    var body: some View {
        if let item = viewModel.content.first(where: { $0.id == contentId }) {
            ScrollView {
                VStack(alignment: .leading) {
                    VStack(alignment: .center) {
                        Text(item.title).font(.largeTitle).bold()
                        if !item.sessions.isEmpty {
                            VStack(alignment: .leading) {
                                ForEach(item.sessions) { s in
                                    if sessionId == 0 || sessionId == s.id {
                                        HStack {
                                            VStack(alignment: .leading) {
                                                HStack {
                                                    Image(systemName: "clock")
                                                    Text("\(dfu.shortDayMonthDayTimeOfWeekFormatter.string(from: s.beginTimestamp)) - \(dfu.shortDayMonthDayTimeOfWeekFormatter.string(from: s.endTimestamp))")
                                                        .font(.subheadline)
                                                }
                                                HStack {
                                                    Image(systemName: "map")
                                                    Text(viewModel.locations.first(where: {$0.id == s.locationId})?.name ?? "unkown").font(.caption)
                                                }
                                            }
                                            .padding(.leading, 10)
                                            .padding(.trailing, 5)
                                            .padding(.vertical, 5)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            VStack(alignment: .trailing) {
                                                HStack(alignment: .center) {
                                                    Button {
                                                        bookmarkAction(id: s.id)
                                                    } label: {
                                                        Image(systemName: bookmarks.map{$0.id}.contains(Int32(s.id)) ? "bookmark.fill" : "bookmark")
                                                    }
                                                }
                                                // .buttonStyle(PlainButtonStyle())
                                            }
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
                            }
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
                    Markdown(item.description).padding()
                }
                if !item.people.isEmpty {
                    // showSpeakers(event: item)
                }
                if !item.links.isEmpty {
                    Divider()
                    showLinks(links: item.links)
                        .padding(15)
                }
            }
            .analyticsScreen(name: "ContentDetailView")
            .navigationBarTitle(Text(""), displayMode: .inline)
        } else {
            _04View(message: "Content \(contentId) not found")
        }

    }
    
    /* func notificationExists() {
        print("Checking for existence of notification for \(eventId)")
        UNUserNotificationCenter.current().getPendingNotificationRequests(completionHandler: { notificationRequests in
            for nr in notificationRequests where nr.identifier == "hackertracker-\(self.eventId)" {
                self.nExists = true
            }
        })
    } */
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

