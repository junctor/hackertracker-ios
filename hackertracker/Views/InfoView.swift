//
//  InfoView.swift
//  hackertracker
//
//  Created by Seth W Law on 6/6/22.
//

import FirebaseFirestoreSwift
import SwiftUI
import WebKit

struct InfoView: View {
    @Binding var tabSelection: Int
    @EnvironmentObject var viewModel: InfoViewModel
    @AppStorage("launchScreen") var launchScreen: String = "Main"
    @AppStorage("showLocaltime") var showLocaltime: Bool = false
    @EnvironmentObject var selected: SelectedConference
    @EnvironmentObject var theme: Theme
    @Environment(\.openURL) private var openURL

    let gridItemLayout = [GridItem(.flexible()), GridItem(.flexible())]

    @State var rick: Int = 0

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .center) {
                    VStack(alignment: .center) {
                        if let con = viewModel.conference {
                            NavigationLink(destination: ConferencesView()) {
                                Text(con.name)
                                    .font(.largeTitle)
                                    .bold()
                                    .foregroundColor(.primary)
                                Image(systemName: "chevron.right")
                            }
                            if con.startDate == con.endDate {
                                Text(DateFormatterUtility.shared.monthDayYearFormatter.string(from: con.endTimestamp))
                                    .font(.headline)
                                    .bold()
                                    .padding(.trailing, 15)
                            } else {
                                Text("\(DateFormatterUtility.shared.monthDayFormatter.string(from: con.startTimestamp)) - \(DateFormatterUtility.shared.monthDayYearFormatter.string(from: con.endTimestamp))")
                                    .font(.headline)
                                    .bold()
                                    .padding(.trailing, 15)
                            }
                            if let tagline = con.tagline {
                                Divider()
                                Text(tagline)
                                    .font(.subheadline)
                            }
                            if let con = viewModel.conference, Date() <= con.kickoffTimestamp {
                                Divider()
                                CountdownView(start: con.startTimestamp)
                            }
                        } else {
                            _04View(message: "Loading", show404: false).preferredColorScheme(theme.colorScheme)
                                .onAppear {
                                    print("InfoView: Need to fetch data for \(selected.code)")
                                    viewModel.fetchData(code: selected.code)
                                }
                        }
                    }
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(15)
                    .background(Color(.systemGray6))
                    .cornerRadius(15)
                    
                    if viewModel.showNews, let article = viewModel.news.first {
                        VStack {
                            Text("Latest News")
                                .font(.headline)
                            Divider()
                            HStack {
                                articleRow(article: article)
                            }
                        }
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(15)
                        .background(Color(.systemGray6))
                        .cornerRadius(15)
                    }
                    
                    if self.viewModel.documents.count > 0 {
                        Text("Documents")
                            .font(.subheadline)
                        LazyVGrid(columns: gridItemLayout, alignment: .center, spacing: 20) {
                            ForEach(self.viewModel.documents, id: \.id) { doc in
                                NavigationLink(destination: DocumentView(title_text: doc.title, body_text: doc.body)) {
                                    CardView(systemImage: "doc", text: doc.title, color: viewModel.colorMode ? ThemeColors.blue : Color(.systemGray6))
                                }
                            }
                        }
                        Divider()
                    }
                    Text("Searchable")
                        .font(.subheadline)
                    LazyVGrid(columns: gridItemLayout, alignment: .center, spacing: 20) {
                        NavigationLink(destination: GlobalSearchView(viewModel: viewModel)) {
                            CardView(systemImage: "magnifyingglass", text: "Search", color: viewModel.colorMode ? theme.carousel() : Color(.systemGray6))
                        }
                        Button {
                            tabSelection = 2
                        } label: {
                            CardView(systemImage: "calendar", text: "Schedule", color: viewModel.colorMode ? theme.carousel() : Color(.systemGray6))
                        }
                        Button {
                            tabSelection = 3
                        } label: {
                            CardView(systemImage: "map", text: "Maps", color: viewModel.colorMode ? theme.carousel() : Color(.systemGray6))
                        }
                        NavigationLink(destination: SpeakersView(speakers: viewModel.speakers)) {
                            CardView(systemImage: "person.crop.rectangle", text: "Speakers", color: viewModel.colorMode ? theme.carousel() : Color(.systemGray6))
                        }
                        if self.viewModel.locations.count > 0 {
                            NavigationLink(destination: LocationView(locations: self.viewModel.locations)) {
                                CardView(systemImage: "mappin.and.ellipse", text: "Locations", color: viewModel.colorMode ? theme.carousel() : Color(.systemGray6))
                            }
                        }
                        if viewModel.faqs.count > 0 {
                            NavigationLink(destination: FAQListView()) {
                                CardView(systemImage: "questionmark.app", text: "FAQ", color: viewModel.colorMode ? theme.carousel() : Color(.systemGray6))
                            }
                        }
                        if viewModel.news.count > 0 {
                            NavigationLink(destination: NewsListView()) {
                                CardView(systemImage: "newspaper", text: "News", color: viewModel.colorMode ? theme.carousel() : Color(.systemGray6))
                            }
                        }
                        if let ott = self.viewModel.tagtypes.first(where: { $0.category == "orga" }) {
                            let sortedTags = ott.tags.sorted { $0.sortOrder < $1.sortOrder }
                            ForEach(sortedTags, id: \.id) { tag in
                                if let _ = viewModel.orgs.first(where: {$0.tag_ids.contains(tag.id)}) {
                                    NavigationLink(destination: OrgsView(title: tag.label, tagId: tag.id)) {
                                        CardView(systemImage: "bag", text: tag.label, color: viewModel.colorMode ? theme.carousel() : Color(.systemGray6))
                                    }
                                }
                            }
                        }
                        let kidsTags = getKidsTags()
                        if kidsTags.count > 0 {
                            NavigationLink(destination: ScheduleView(tagIds: kidsTags, includeNav: false, navTitle: "Kids Content")) {
                                CardView(systemImage: "figure.and.child.holdinghands", text: "Kids Content", color: viewModel.colorMode ? theme.carousel() : Color(.systemGray6))
                            }
                        }
                    }
                    Divider()
                    if self.viewModel.conference?.enableMerch ?? false {
                        Text("Merch")
                        .font(.subheadline)
                        NavigationLink(destination: ProductsView()) {
                            CardView(systemImage: "dollarsign", text: "Merch", color: viewModel.colorMode ? ThemeColors.drkGreen : Color(.systemGray6))
                        }
                        Divider()
                    }
                    if let url = URL(string: "mailto:hackertracker@defcon.org") {
                        HStack {
                            Button {
                                openURL(url)
                            } label: {
                                Label("Contact Us", systemImage: "person.fill.questionmark")
                            }
                        }
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(15)
                        .background(Color(.systemGray6))
                        .cornerRadius(15)
                    }
                    if let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                        Text("#hackertracker iOS v\(v)")
                            .font(.caption2)
                            .onTapGesture {
                                tapped()
                            }
                    } else {
                        Text("#hackertracker iOS")
                            .font(.caption2)
                            .onTapGesture {
                                tapped()
                            }
                    }
                }
                .padding(5)
                .onAppear {
                    print("InfoView: selectedCode: \(selected.code)")
                    print("ScheduleView: Current launchscreen is: \(launchScreen)")
                    launchScreen = "Main"
                    viewModel.showLocaltime = showLocaltime
                }
            }
        }
        .navigationViewStyle(.stack)
    }
    
    func getKidsTags() -> [Int] {
        var kidsTags: [Int] = []
        for kidstype in viewModel.tagtypes.filter({$0.category == "content" && $0.isBrowsable == true}) {
            do {
                let re = try Regex("[Kk]id")
                for tag in kidstype.tags.filter({$0.label.contains(re)}) {
                    kidsTags.append(tag.id)
                }
            } catch {
                print("Regex failed")
            }
        }
        print("KidsTags: \(kidsTags)")
        return kidsTags
    }

    func tapped() {
        rick += 1
        if rick >= 7 {
            print("Roll away!")
            if let url = URL(string: "https://www.youtube.com/watch?v=xMHJGd3wwZk") {
                openURL(url)
            }
            rick = 0
        }
    }
}

struct CardView: View {
    var systemImage: String
    var text: String
    var color: Color
    @EnvironmentObject var viewModel: InfoViewModel

    var body: some View {
        if viewModel.colorMode {
            HStack {
                Image(systemName: systemImage)
                Text(text)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(15)
            .background(color.gradient)
            .cornerRadius(15)
        } else {
            HStack {
                Image(systemName: systemImage)
                Text(text)
            }
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(15)
            .background(color)
            .cornerRadius(15)
        }
    }
}

struct InfoView_Previews: PreviewProvider {
    static var previews: some View {
        Text("Info View")
    }
}
