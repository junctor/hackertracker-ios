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
    @Binding var tappedMainTwice: Bool
    @EnvironmentObject var viewModel: InfoViewModel
    @AppStorage("launchScreen") var launchScreen: String = "Main"
    @AppStorage("showLocaltime") var showLocaltime: Bool = false
    @EnvironmentObject var selected: SelectedConference
    @EnvironmentObject var theme: Theme
    @Environment(\.openURL) private var openURL

    let gridItemLayout = [GridItem(.flexible()), GridItem(.flexible())]

    @State var rick: Int = 0
    @State var schedule = UUID()

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
                                CountdownView(start: con.kickoffTimestamp)
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
                    if let con = self.viewModel.conference, let menu = self.viewModel.menus.first(where: { $0.id == con.homeMenuId}) {
                        MenuView(menu: menu, tabSelection: $tabSelection, tappedMainTwice: $tappedMainTwice)
                        
                    } else {
                        
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
                                    if viewModel.orgs.first(where: {$0.tag_ids.contains(tag.id)}) != nil {
                                        NavigationLink(destination: OrgsView(title: tag.label, tagId: tag.id, tappedTwice: $tappedMainTwice)) {
                                            CardView(systemImage: "bag", text: tag.label, color: viewModel.colorMode ? theme.carousel() : Color(.systemGray6))
                                        }
                                    }
                                }
                            }
                            let kidsTags = getKidsTags()
                            if kidsTags.count > 0 {
                                NavigationLink(destination: ScheduleView(tagIds: kidsTags, includeNav: false, navTitle: "Kids Content", tappedScheduleTwice: $tappedMainTwice, schedule: $schedule)) {
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
                        }
                    }
                    if let url = URL(string: "mailto:hackertracker@defcon.org") {
                        Divider()
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
                .analyticsScreen(name: "InfoView")
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

struct MenuView: View {
    var menu: InfoMenu
    var useGrid: Bool = true
    @Binding var tabSelection: Int
    @Binding var tappedMainTwice: Bool
    @EnvironmentObject var viewModel: InfoViewModel
    @EnvironmentObject var theme: Theme
    let gridItemLayout = [GridItem(.flexible()), GridItem(.flexible())]
    @State var schedule = UUID()
    
    var body: some View {
        Text(menu.title)
            .font(.title3)
        LazyVGrid(columns: useGrid ? gridItemLayout : [GridItem(.flexible())], alignment: .center, spacing: 20) {
            ForEach(menu.items.sorted(by: {$0.sortOrder < $1.sortOrder}), id: \.id) { item in
                switch item.function {
                case "document":
                    if let doc = self.viewModel.documents.first(where: { $0.id == item.documentId }) {
                        NavigationLink(destination: DocumentView(title_text: doc.title, body_text: doc.body)) {
                            CardView(systemImage: item.symbol ?? "doc", text: doc.title, color: viewModel.colorMode ? ThemeColors.blue : Color(.systemGray6))
                            }
                    }
                
                case "locations":
                    NavigationLink(destination: LocationView(locations: self.viewModel.locations)) {
                        CardView(systemImage: item.symbol ?? "mappin.and.ellipse", text: "Locations", color: viewModel.colorMode ? theme.carousel() : Color(.systemGray6))
                    }
                case "maps":
                    Button {
                        tabSelection = 3
                    } label: {
                        CardView(systemImage: item.symbol ?? "map", text: "Maps", color: viewModel.colorMode ? theme.carousel() : Color(.systemGray6))
                    }
                case "menu":
                    if let menuId = item.menuId, let m = viewModel.menus.first(where: {$0.id == menuId}) {
                        NavigationLink(destination: ScrollView {
                            MenuView(menu: m, useGrid: false, tabSelection: $tabSelection, tappedMainTwice: $tappedMainTwice)
                            
                        }
                            .padding(15)
                        ) {
                            CardView(systemImage: item.symbol ?? "menucard", text: item.title, color: viewModel.colorMode ? theme.carousel() : Color(.systemGray6))
                        }
                    }
                case "news":
                    NavigationLink(destination: NewsListView()) {
                        CardView(systemImage: item.symbol ?? "newspaper", text: "News", color: viewModel.colorMode ? theme.carousel() : Color(.systemGray6))
                    }
                case "content":
                    NavigationLink(destination: ContentListView(content: viewModel.content)) {
                        CardView(systemImage: item.symbol ?? "list.dash", text: item.title, color: viewModel.colorMode ? theme.carousel() : Color(.systemGray6))
                    }
                case "organizations":
                    if viewModel.orgs.first(where: {$0.tag_ids.contains(item.appliedTagIds[0])}) != nil {
                        NavigationLink(destination: OrgsView(title: item.title, tagId: item.appliedTagIds[0], tappedTwice: $tappedMainTwice)) {
                            CardView(systemImage: item.symbol ?? "figure.walk", text: item.title, color: viewModel.colorMode ? theme.carousel() : Color(.systemGray6))
                        }
                    }
                case "people":
                    NavigationLink(destination: SpeakersView(speakers: viewModel.speakers)) {
                        CardView(systemImage: item.symbol ?? "person.3", text: "Speakers", color: viewModel.colorMode ? theme.carousel() : Color(.systemGray6))
                    }
                case "products":
                    if let c = self.viewModel.conference, c.enableMerch {
                        NavigationLink(destination: ProductsView()) {
                            CardView(systemImage: item.symbol ?? "tshirt", text: "Merch", color: viewModel.colorMode ? ThemeColors.drkGreen : Color(.systemGray6))
                        }
                    }
                case "faq":
                    NavigationLink(destination: FAQListView()) {
                        CardView(systemImage: item.symbol ?? "questionmark.app", text: "FAQ", color: viewModel.colorMode ? theme.carousel() : Color(.systemGray6))
                    }
                case "schedule":
                    if item.appliedTagIds.count > 0 {
                        NavigationLink(destination: ScheduleView(tagIds: item.appliedTagIds, includeNav: false, navTitle: item.title, tappedScheduleTwice: $tappedMainTwice, schedule: $schedule)) {
                            CardView(systemImage: item.symbol ?? "calendar", text: item.title, color: viewModel.colorMode ? theme.carousel() : Color(.systemGray6))
                        }
                    } else {
                        Button {
                            tabSelection = 2
                        } label: {
                            CardView(systemImage: item.symbol ?? "calendar", text: "Schedule", color: viewModel.colorMode ? theme.carousel() : Color(.systemGray6))
                        }
                    }
                case "search":
                     NavigationLink(destination: GlobalSearchView(viewModel: viewModel)) {
                         CardView(systemImage: item.symbol ?? "magnifyingglass", text: "Search", color: viewModel.colorMode ? theme.carousel() : Color(.systemGray6))
                     }
                default:
                    EmptyView()
                }
                
            }
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
