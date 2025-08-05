//
//  InfoView.swift
//  hackertracker
//
//  Created by Seth W Law on 6/6/22.
//

import FirebaseFirestore
import SwiftUI
import WebKit

struct InfoView: View {
    @Binding var tabSelection: Int
    //@Binding var tappedMainTwice: Bool
    @EnvironmentObject var viewModel: InfoViewModel
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("showLocaltime") var showLocaltime: Bool = false
    @AppStorage("colorMode") var colorMode: Bool = false
    @EnvironmentObject var selected: SelectedConference
    @EnvironmentObject var theme: Theme
    @EnvironmentObject var filters: Filters
    @EnvironmentObject var consViewModel: ConferencesViewModel
    @Environment(\.openURL) private var openURL
    @State private var showUpdateButton = false
    @State private var appStoreVersion: String?
    @State private var showOpenUrl = false
    @State private var path = NavigationPath()
    @State private var sharedEvents:[Event] = []
    @State private var eventDay = ""
    @State private var searchText = ""
    @FetchRequest(sortDescriptors: []) var bookmarks: FetchedResults<Bookmarks>

    let gridItemLayout = [GridItem(.flexible()), GridItem(.flexible())]

    @State var rick: Int = 0
    @State var schedule = UUID()

    var body: some View {
        NavigationStack(path: $path) {
            if let emergId = viewModel.conference?.emergencyDocId, emergId > 0, let doc = viewModel.documents.first(where: {$0.id == emergId}) {
                NavigationLink(destination: DocumentView(title_text: doc.title, body_text: doc.body, color: ThemeColors.red, systemImage: "exclamationmark.triangle.fill")) {
                    CardView(systemImage: "exclamationmark.triangle.fill", text: doc.title, color: ThemeColors.red, subtitle: "Tap for more details" )
                        .frame(height: 40)
                        .cornerRadius(0)
                }
            }
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
                                .task {
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
                    if showUpdateButton {
                        if let url = URL(string: "itms-apps://itunes.apple.com/app/id1021141595") {
                            Divider()
                            Button {
                                openURL(url)
                            } label: {
                                Label("HackerTracker Update (v\(appStoreVersion ?? "n/a")) Available", systemImage: "arrow.triangle.2.circlepath.circle")
                            }
                            .foregroundColor(colorMode ? .white : .primary)
                            .frame(maxWidth: .infinity)
                            .padding(15)
                            .background(colorMode ? theme.carousel() : Color(.systemGray6))
                            .cornerRadius(15)
                            Divider()
                        }
                    }
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
                        MenuView(menu: menu, tabSelection: $tabSelection)
                        
                    } else {
                        
                        if self.viewModel.documents.count > 0 {
                            Text("Documents")
                                .font(.subheadline)
                            LazyVGrid(columns: gridItemLayout, alignment: .center, spacing: 20) {
                                ForEach(self.viewModel.documents, id: \.id) { doc in
                                    NavigationLink(destination: DocumentView(title_text: doc.title, body_text: doc.body)) {
                                        CardView(systemImage: "doc", text: doc.title, color: colorMode ? ThemeColors.blue : Color(.systemGray6))
                                    }
                                }
                            }
                            Divider()
                        }
                        Text("Searchable")
                            .font(.subheadline)
                        LazyVGrid(columns: gridItemLayout, alignment: .center, spacing: 20) {
                            if let emergId = viewModel.conference?.emergencyDocId, emergId > 0 {
                                if let doc = viewModel.documents.first(where: {$0.id == emergId}) {
                                    NavigationLink(destination: DocumentView(title_text: doc.title, body_text: doc.body)) {
                                        CardView(systemImage: "doc", text: doc.title, color: ThemeColors.red)
                                    }
                                }
                            }
                            NavigationLink(destination: GlobalSearchView()) {
                                CardView(systemImage: "magnifyingglass", text: "Search", color: colorMode ? theme.carousel() : Color(.systemGray6))
                            }
                            Button {
                                tabSelection = 2
                            } label: {
                                CardView(systemImage: "calendar", text: "Schedule", color: colorMode ? theme.carousel() : Color(.systemGray6))
                            }
                            Button {
                                tabSelection = 3
                            } label: {
                                CardView(systemImage: "map", text: "Maps", color: colorMode ? theme.carousel() : Color(.systemGray6))
                            }
                            NavigationLink(destination: SpeakersView(speakers: viewModel.speakers)) {
                                CardView(systemImage: "person.crop.rectangle", text: "Speakers", color: colorMode ? theme.carousel() : Color(.systemGray6))
                            }
                            if self.viewModel.locations.count > 0 {
                                NavigationLink(destination: LocationView(locations: self.viewModel.locations)) {
                                    CardView(systemImage: "mappin.and.ellipse", text: "Locations", color: colorMode ? theme.carousel() : Color(.systemGray6))
                                }
                            }
                            if viewModel.faqs.count > 0 {
                                NavigationLink(destination: FAQListView()) {
                                    CardView(systemImage: "questionmark.app", text: "FAQ", color: colorMode ? theme.carousel() : Color(.systemGray6))
                                }
                            }
                            if viewModel.news.count > 0 {
                                NavigationLink(destination: NewsListView()) {
                                    CardView(systemImage: "newspaper", text: "News", color: colorMode ? theme.carousel() : Color(.systemGray6))
                                }
                            }
                            if let ott = self.viewModel.tagtypes.first(where: { $0.category == "orga" }) {
                                let sortedTags = ott.tags.sorted { $0.sortOrder < $1.sortOrder }
                                ForEach(sortedTags, id: \.id) { tag in
                                    if viewModel.orgs.first(where: {$0.tag_ids.contains(tag.id)}) != nil {
                                        NavigationLink(destination: OrgsView(title: tag.label, tagId: tag.id, tabSelection: $tabSelection)) {
                                            CardView(systemImage: "bag", text: tag.label, color: colorMode ? theme.carousel() : Color(.systemGray6))
                                        }
                                    }
                                }
                            }
                            let kidsTags = getKidsTags()
                            if kidsTags.count > 0 {
                                Button {
                                    filters.filters.removeAll()
                                    for id in kidsTags {
                                        filters.filters.insert(id)
                                    }
                                    tabSelection = 2
                                } label: {
                                    // NavigationLink(destination: ScheduleView(tagIds: [1337], includeNav: false, navTitle: item.title)) {
                                    CardView(systemImage: "figure.and.child.holdinghands", text: "Kids Content", color: colorMode ? theme.carousel() : Color(.systemGray6))
                                    // }
                                }
                            }
                        }
                        Divider()
                        if self.viewModel.conference?.enableMerch ?? false {
                            Text("Merch")
                                .font(.subheadline)
                            NavigationLink(destination: ProductsView()) {
                                CardView(systemImage: "dollarsign", text: "Merch", color: colorMode ? ThemeColors.drkGreen : Color(.systemGray6))
                            }
                        }
                    }
                    if let url = URL(string: "mailto:hackertracker@defcon.org?subject=HackerTracker&body=\r\n-----------------------\r\nVersion: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] ?? "Unknown")  (\(Bundle.main.infoDictionary?["CFBundleVersion"] ?? "Unknown"))\r\niOS: \(ProcessInfo.processInfo.operatingSystemVersionString)\r\nApp: \(Bundle.main.bundleIdentifier ?? "Unknown")\r\n-----------------------\r\n".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!) {
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
                    HStack {
                        if let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                            Button {
                                tapped()
                            } label: {
                                Text("#hackertracker iOS v\(v)")
                                    .font(.caption2)
                                    .frame(maxWidth: .infinity)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            Button {
                                tapped()
                            } label: {
                                Text("#hackertracker iOS")
                                    .font(.caption2)
                                    .frame(maxWidth: .infinity)
                                    .foregroundColor(.secondary)
                            }
                        }
                        if viewModel.easterEgg {
                            ZStack(alignment: .bottomTrailing){
                                Button {
                                    playChik()
                                    print("chikin")
                                } label: {
                                    Label("", systemImage: "bird.circle")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    
                    .padding(5)

                }
                .padding(5)
                /*
                 @EnvironmentObject var viewModel: InfoViewModel
                 @EnvironmentObject var selected: SelectedConference
                 @EnvironmentObject var theme: Theme
                 @EnvironmentObject var filters: Filters
                 
                if #available(iOS 17.0, *) {
                    .onChange(of: selected.code) {
                        print("InfoView: selected changed")
                    }
                    .onChange(of: filters.filters) {
                        print("InfoView: filters changed")
                    }
                } */
                .onAppear {
                    print("InfoView: selectedCode: \(selected.code)")
                    if colorMode { theme.index = 0 }
                    checkAppUpdate()
                }
                .analyticsScreen(name: "InfoView")
                .onOpenURL(perform: { url in
                    if let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                        let queryItems = urlComponents.queryItems
                        //let path = urlComponents.path
                        //let host = urlComponents.host ?? ""
                        print("opened with url \(url)")
                        if let urlConference = url.host {
                            if urlConference == viewModel.conference?.code {
                                print("Conference is \(urlConference), checking path to \(url.path)")
                                filters.filters.removeAll()
                            } else {
                                print("Need to switch conference to \(urlConference)")
                                if let conf = consViewModel.conferences.first(where: {$0.code == urlConference}) {
                                    print("Changing to \(conf.name)")
                                    selected.code = conf.code
                                    filters.filters.removeAll()
                                    viewModel.fetchData(code: conf.code)
                                }
                            }
                            switch url.path {
                            case "/c", "/content":
                                print("Open Content ID")
                                
                            case "/s", "/share":
                                print("Share Content")
                                if let sharedIds = queryItems?.first(where: { $0.name == "ids" })?.value {
                                    print("Share IDs: \(sharedIds)")
                                    
                                    for id in sharedIds.split(separator: ",") {
                                        if let e = viewModel.events.first(where: { $0.id == Int(id) }) {
                                            sharedEvents.append(e)
                                        } else {
                                            print("Invalid ID: \(id) for conference \(urlConference)")
                                        }
                                    }
                                    // Change Tab To Main Screen
                                    if tabSelection != 1 {
                                        tabSelection = 1
                                    }
                                    //print("Valid Ids: \(ids)")
                                    // NavigationLink("Go to Content List View", destination: ContentListView(content: sharedContent, title: "Shared Content"))
                                    if sharedEvents.count > 0 {
                                        path.append("SharedEvents")
                                    }
                                }
                            default:
                                print("No corresponding URL")
                            }
                            
                        }
                    }
                       
                })
            }
            .navigationDestination(for: String.self) { value in
                switch value {
                case "SharedEvents":
                    EventScrollView(events:
                        sharedEvents
                            .filters(typeIds: filters.filters, bookmarks: bookmarks.map { $0.id }, tagTypes: viewModel.tagtypes)
                            .search(text: searchText)
                            .eventDayGroup(
                                showLocaltime: showLocaltime, conference: viewModel.conference
                            ),
                      dayTag: eventDay,
                      showPastEvents: true, includeNav: true,
                      showLocaltime: $showLocaltime)
                    //EventsView(sharedEvents: sharedEvents)
                    .onAppear {
                        print("Navigating to \(value)")
                    }
                default:
                    _04View(message: "Unknown destination: \(value)")
                }
            }
        }
    }
    
    func checkAppUpdate() {
        guard let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return
        }

        guard let url = URL(string: "https://itunes.apple.com/lookup?bundleId=org.beezle.hackertracker") else {
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                    let results = json["results"] as? [[String: Any]],
                    let latestAppStoreVersion = results.first?["version"] as? String {
                        if latestAppStoreVersion.compare(currentVersion, options: .numeric) == .orderedDescending {
                            self.appStoreVersion = latestAppStoreVersion
                            self.showUpdateButton = true
                        }
                    }
            } catch {
                print("Error parsing JSON: \(error.localizedDescription)")
            }
        }.resume()
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
        // print("KidsTags: \(kidsTags)")
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
    // @Binding var tappedMainTwice: Bool
    @EnvironmentObject var viewModel: InfoViewModel
    @EnvironmentObject var theme: Theme
    @EnvironmentObject var filters: Filters
    @AppStorage("colorMode") var colorMode: Bool = false
    let gridItemLayout = [GridItem(.flexible()), GridItem(.flexible())]
    @State var schedule = UUID()
    @FetchRequest(sortDescriptors: []) var readnews: FetchedResults<News>
    
    var body: some View {
        Text(menu.title)
            .font(.title3)
        LazyVGrid(columns: useGrid ? gridItemLayout : [GridItem(.flexible())], alignment: .center, spacing: 20) {
            ForEach(menu.items.sorted(by: {$0.sortOrder < $1.sortOrder}), id: \.id) { item in
                switch item.function {
                case "document":
                    if let doc = self.viewModel.documents.first(where: { $0.id == item.documentId }) {
                        NavigationLink(destination: DocumentView(title_text: doc.title, body_text: doc.body)) {
                            CardView(systemImage: item.symbol ?? "doc", text: doc.title, color: colorMode ? ThemeColors.blue : Color(.systemGray6))
                            }
                    }
                
                case "locations":
                    NavigationLink(destination: LocationView(locations: self.viewModel.locations)) {
                        CardView(systemImage: item.symbol ?? "mappin.and.ellipse", text: "Locations", color: colorMode ? theme.carousel() : Color(.systemGray6))
                    }
                case "maps":
                    Button {
                        tabSelection = 3
                    } label: {
                        CardView(systemImage: item.symbol ?? "map", text: "Maps", color: colorMode ? theme.carousel() : Color(.systemGray6))
                    }
                case "menu":
                    if let menuId = item.menuId, let m = viewModel.menus.first(where: {$0.id == menuId}) {
                        NavigationLink(destination: ScrollView {
                            MenuView(menu: m, useGrid: false, tabSelection: $tabSelection)
                        }
                            .padding(15)
                        ) {
                            CardView(systemImage: item.symbol ?? "menucard", text: item.title, color: colorMode ? theme.carousel() : Color(.systemGray6))
                        }
                    }
                case "news":
                    NavigationLink(destination: NewsListView()) {
                        CardView(systemImage: item.symbol ?? "newspaper", text: "News", color: colorMode ? theme.carousel() : Color(.systemGray6))
                    }
                case "content":
                    NavigationLink(destination: ContentListView(content: viewModel.content)) {
                        CardView(systemImage: item.symbol ?? "list.dash", text: item.title, color: colorMode ? theme.carousel() : Color(.systemGray6))
                    }
                case "organizations":
                    if viewModel.orgs.first(where: {$0.tag_ids.contains(item.appliedTagIds[0])}) != nil {
                        NavigationLink(destination: OrgsView(title: item.title, tagId: item.appliedTagIds[0], tabSelection: $tabSelection)) {
                            CardView(systemImage: item.symbol ?? "figure.walk", text: item.title, color: colorMode ? theme.carousel() : Color(.systemGray6))
                        }
                    }
                case "people":
                    NavigationLink(destination: SpeakersView(speakers: viewModel.speakers)) {
                        CardView(systemImage: item.symbol ?? "person.3", text: "Speakers", color: colorMode ? theme.carousel() : Color(.systemGray6))
                    }
                case "products":
                    if let c = self.viewModel.conference, c.enableMerch {
                        NavigationLink(destination: ProductsView()) {
                            CardView(systemImage: item.symbol ?? "tshirt", text: "Merch", color: colorMode ? ThemeColors.drkGreen : Color(.systemGray6))
                        }
                    }
                case "faq":
                    NavigationLink(destination: FAQListView()) {
                        CardView(systemImage: item.symbol ?? "questionmark.app", text: "FAQ", color: colorMode ? theme.carousel() : Color(.systemGray6))
                    }
                case "schedule":
                        Button {
                            tabSelection = 2
                        } label: {
                            CardView(systemImage: item.symbol ?? "calendar", text: "Schedule", color: colorMode ? theme.carousel() : Color(.systemGray6))
                        }
                case "schedule_bookmark":
                    Button {
                        filters.filters = [1337]
                        tabSelection = 2
                    } label: {
                        CardView(systemImage: item.symbol ?? "calendar", text: item.title, color: colorMode ? theme.carousel() : Color(.systemGray6))
                    }
                case "search":
                     NavigationLink(destination: GlobalSearchView()) {
                         CardView(systemImage: item.symbol ?? "magnifyingglass", text: "Search", color: colorMode ? theme.carousel() : Color(.systemGray6))
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
    var subtitle: String?
    var foregroundColor: Color?
    @EnvironmentObject var viewModel: InfoViewModel
    @AppStorage("colorMode") var colorMode: Bool = false

    var body: some View {
        if colorMode {
            HStack {
                Image(systemName: systemImage)
                if let sub = subtitle {
                    VStack {
                        Text(text)
                        Text(sub)
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    Text(text)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(15)
            .background(color)
            .cornerRadius(15)
        } else {
            HStack {
                Image(systemName: systemImage)
                if let sub = subtitle {
                    VStack {
                        Text(text)
                        Text(sub)
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    Text(text)
                }
            }
            .foregroundColor(foregroundColor ?? .primary)
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
