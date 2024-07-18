//
//  FAQListView.swift
//  hackertracker
//
//  Created by Seth Law on 7/3/23.
//

import SwiftUI

struct ContentListView: View {
    var content: [Content]
    @State private var searchText = ""
    @State var filters: Set<Int> = []
    @State private var showFilters = false
    @EnvironmentObject var viewModel: InfoViewModel
    @FetchRequest(sortDescriptors: []) var bookmarks: FetchedResults<Bookmarks>
    
    func contentGroup() -> [String.Element: [Content]] {
        return Dictionary(grouping: content.search(text: searchText).filter { $0.tagIds.intersects(with: filters) || filters.isEmpty || (filters.contains(1337) && $0.sessions.map {Int32($0.id)}.intersects(with: bookmarks.map{$0.id}))}, by: { $0.title.lowercased().first ?? "-" })
    }

    var body: some View {
        VStack {
            ScrollView {
                ScrollViewReader { _ in
                    LazyVStack(alignment: .leading, pinnedViews: [.sectionHeaders]) {
                        ForEach(self.contentGroup().sorted {
                            $0.key < $1.key
                        }, id: \.key) { char, content in
                            ContentData(char: char, content: content, filters: filters)
                        }
                    }
                }
                .listStyle(.plain)
            }
            .searchable(text: $searchText)
            .sheet(isPresented: $showFilters) {
              EventFilters(
                tagtypes: viewModel.tagtypes.filter {
                  $0.category == "content" && $0.isBrowsable == true
                }, showFilters: $showFilters, filters: $filters
              )
            }
        }
        .navigationTitle("All Content")
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                  showFilters.toggle()
                } label: {
                  Image(
                    systemName: filters
                      .isEmpty
                      ? "line.3.horizontal.decrease.circle"
                      : "line.3.horizontal.decrease.circle.fill")
                }
            }
        }
        /*  */
        .analyticsScreen(name: "ContentListView")
    }

    /* var body: some View {
        List {
            //ForEach(self.viewModel.content.search(text: searchText)) { faq in
            ForEach(self.content) { item in
                contentRow(item: item)
            }
        }
        // .searchable(text: $searchText)
        .navigationTitle("All Content")
        .analyticsScreen(name: "ContentListView")
    } */
}

struct ContentData: View {
    let char: String.Element
    let content: [Content]
    var filters: Set<Int>
    @EnvironmentObject var theme: Theme
    @FetchRequest(sortDescriptors: []) var bookmarks: FetchedResults<Bookmarks>

    var body: some View {
        Section(header: Text(String(char.uppercased()))
            .font(.subheadline)
            .padding(1)
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6))
        ) {
            ForEach(content, id: \.id) { item in
                NavigationLink(destination: ContentDetailView(contentId: item.id)) {
                    ContentCell(content: item, bookmarks: bookmarks.map { $0.id }, showDay: false)
               }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .listStyle(.plain)
    }
}

struct ContentRow: View {
    let item: Content
    let themeColor: Color

    var body: some View {
        HStack {
            Rectangle().fill(themeColor)
                .frame(width: 6)
                .frame(maxHeight: .infinity)
            VStack(alignment: .leading) {
                Text(item.title)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
        }
    }
}

/* struct ContentListView_Previews: PreviewProvider {
    static var previews: some View {
        //ContentListView()
    }
} */
