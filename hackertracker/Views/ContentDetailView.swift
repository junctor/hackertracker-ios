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
    @State var showAddContentModal = false
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
                                                    Button {
                                                        showAddContentModal.toggle()
                                                    } label: {
                                                        Image(systemName: "clock")
                                                    }
                                                    Text("\(dfu.shortDayMonthDayTimeOfWeekFormatter.string(from: s.beginTimestamp))-\(dfu.hourMinuteTimeFormatter.string(from: s.endTimestamp))")
                                                        .font(.subheadline)
                                                }
                                                .sheet(isPresented: $showAddContentModal) {
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
                                                    }
                                                    MoreContentMenu(content: item, session: s)
                                                }
                                                
                                                // .buttonStyle(PlainButtonStyle())
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
                    showPeople(content: item)
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
}

struct showPeople: View {
    var content: Content
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
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .padding(15)
                                .background(theme.carousel().gradient)
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

