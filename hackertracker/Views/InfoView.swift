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
    @Environment(InfoViewModel.self) private var viewModel
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("showLocaltime") var showLocaltime: Bool = false
    @AppStorage("colorMode") var colorMode: Bool = false
    @EnvironmentObject var selected: SelectedConference
    @EnvironmentObject var theme: Theme
    @EnvironmentObject var filters: Filters
    @Environment(ConferencesViewModel.self) private var consViewModel
    @Environment(\.openURL) private var openURL
    @State private var showUpdateButton = false
    @State private var appStoreVersion: String?
    @State private var showOpenUrl = false
    @State private var path = NavigationPath()
    @State private var sharedEvents:[Event] = []
    /// Combined-bookmarks-across-conferences store. Refreshed via .task(id:)
    /// whenever bookmarks or the conferences list changes.
    @State private var sharedSchedule = SharedScheduleStore()
    @State private var eventDay = ""
    @State private var searchText = ""
    @FetchRequest(sortDescriptors: []) var bookmarks: FetchedResults<Bookmarks>

    let gridItemLayout = [GridItem(.flexible()), GridItem(.flexible())]

    @State var rick: Int = 0
    @State var schedule = UUID()

    var body: some View {
        // Phase 4 follow-up: observe DateFormatterUtility tz changes so
        // conference start/end date labels (and any descendants reading dfu)
        // refresh when the active timezone shifts.
        let _ = DateFormatterUtility.shared.tzGeneration
        NavigationStack(path: $path) {
            if let emergId = viewModel.conference?.emergencyDocId, emergId > 0, let doc = viewModel.documentsById[emergId] {
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
                                    Log.app.debug("InfoView fetch data for \(selected.code, privacy: .public)")
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
                                if let doc = viewModel.documentsById[emergId] {
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
                            // Combined-schedule entry-point: only when SharedScheduleStore
                            // has resolved >=2 overlapping conferences with bookmarks in each.
                            if sharedSchedule.isAvailable {
                                NavigationLink(destination: SharedScheduleView()) {
                                    CardView(systemImage: "calendar.badge.plus", text: "Combined Schedule", color: colorMode ? theme.carousel() : Color(.systemGray6))
                                }
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
                                    Log.ui.debug("easter egg: chikin")
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
                 @Environment(InfoViewModel.self) private var viewModel
                 @EnvironmentObject var selected: SelectedConference
                 @EnvironmentObject var theme: Theme
                 @EnvironmentObject var filters: Filters
                 
                if #available(iOS 17.0, *) {
                    .onChange(of: selected.code) {
                        Log.app.debug("InfoView selected changed")
                    }
                    .onChange(of: filters.filters) {
                        Log.app.debug("InfoView filters changed")
                    }
                } */
                .task(id: SharedScheduleRefreshKey(
                    bookmarkCount: bookmarks.count,
                    confCount: consViewModel.conferences.count
                )) {
                    // Polish: refresh combined-schedule data when the bookmark
                    // set or conferences list changes. Triggers on first appear
                    // (id changes from nil) plus any subsequent edit.
                    let ids = Set(bookmarks.map { Int($0.id) })
                    await sharedSchedule.refresh(
                        bookmarkIds: ids,
                        allConferences: consViewModel.conferences
                    )
                }
                .onAppear {
                    Log.app.debug("InfoView selectedCode=\(selected.code, privacy: .public)")
                    if colorMode { theme.index = 0 }
                    checkAppUpdate()
                }
                .analyticsScreen(name: "InfoView")
                .environment(sharedSchedule)
                .onOpenURL(perform: { url in
                    if let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                        let queryItems = urlComponents.queryItems
                        //let path = urlComponents.path
                        //let host = urlComponents.host ?? ""
                        Log.app.info("deep link opened: \(url, privacy: .public)")
                        if let urlConference = url.host {
                            if urlConference == viewModel.conference?.code {
                                Log.app.debug("deep link conference=\(urlConference, privacy: .public) path=\(url.path, privacy: .public)")
                                filters.filters.removeAll()
                            } else {
                                Log.app.info("deep link wants conference \(urlConference, privacy: .public)")
                                if let conf = consViewModel.conferences.first(where: {$0.code == urlConference}) {
                                    Log.app.info("switching to \(conf.name, privacy: .public)")
                                    selected.code = conf.code
                                    filters.filters.removeAll()
                                    viewModel.fetchData(code: conf.code)
                                }
                            }
                            // Phase 5c: deep-link router. Supported paths:
                            //   /                        Just switch conferences (handled above).
                            //   /c, /content?id=N        Open content detail.
                            //   /e, /event?id=N          Open event detail.
                            //   /s, /share?ids=N,N,N     Open shared bookmark schedule.
                            switch url.path {
                            case "", "/":
                                Log.app.debug("deep link: bare conference path, already switched")

                            case "/c", "/content":
                                Log.app.debug("deep link: open content")
                                if let raw = queryItems?.first(where: { $0.name == "id" })?.value,
                                   let id = Int(raw) {
                                    if tabSelection != 1 { tabSelection = 1 }
                                    path.append("content/\(id)")
                                } else {
                                    Log.app.error("deep link: /content missing or invalid `id` query item")
                                }

                            case "/e", "/event":
                                Log.app.debug("deep link: open event")
                                // Events navigate to their parent Content. Resolve the
                                // event's contentId now and push the corresponding
                                // content route. Falls back to a no-op + log if the
                                // event isn't in the current snapshot.
                                if let raw = queryItems?.first(where: { $0.name == "id" })?.value,
                                   let id = Int(raw) {
                                    if tabSelection != 1 { tabSelection = 1 }
                                    if let event = viewModel.events.first(where: { $0.id == id }) {
                                        path.append("content/\(event.contentId)")
                                    } else {
                                        Log.app.error("deep link: event \(id) not found in current conference")
                                    }
                                } else {
                                    Log.app.error("deep link: /event missing or invalid `id` query item")
                                }

                            case "/s", "/share":
                                Log.app.debug("deep link: share content")
                                if let sharedIds = queryItems?.first(where: { $0.name == "ids" })?.value {
                                    Log.app.debug("share ids: \(sharedIds, privacy: .public)")

                                    for id in sharedIds.split(separator: ",") {
                                        if let e = viewModel.events.first(where: { $0.id == Int(id) }) {
                                            sharedEvents.append(e)
                                        } else {
                                            Log.app.error("invalid share id=\(id, privacy: .public) conf=\(urlConference, privacy: .public)")
                                        }
                                    }
                                    if tabSelection != 1 {
                                        tabSelection = 1
                                    }
                                    if sharedEvents.count > 0 {
                                        path.append("SharedEvents")
                                    }
                                }

                            default:
                                Log.app.error("deep link: unknown path \(url.path, privacy: .public)")
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
                            .search(text: searchText, speakers: viewModel.speakers)
                            .eventDayGroup(
                                showLocaltime: showLocaltime, conference: viewModel.conference
                            ),
                      dayTag: eventDay,
                      showPastEvents: true, includeNav: true,
                      showLocaltime: $showLocaltime)
                    //EventsView(sharedEvents: sharedEvents)
                    .onAppear {
                        Log.app.debug("navigating to \(value, privacy: .public)")
                    }
                default:
                    // Phase 5c: deep-link routes pushed by .onOpenURL.
                    // Format: "content/<id>". Event deep links resolve to a
                    // content id before being pushed (events have no detail
                    // view of their own; tapping a row navigates to the
                    // parent Content).
                    if value.hasPrefix("content/"),
                       let id = Int(value.dropFirst("content/".count)) {
                        ContentDetailView(contentId: id)
                            .onAppear { Log.app.debug("deep link nav -> content/\(id)") }
                    } else {
                        _04View(message: "Unknown destination: \(value)")
                    }
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
                            // URLSession completion runs off the main actor;
                            // hop back before mutating @State properties.
                            Task { @MainActor in
                                self.appStoreVersion = latestAppStoreVersion
                                self.showUpdateButton = true
                            }
                        }
                    }
            } catch {
                Log.app.error("JSON parse error: \(error.localizedDescription, privacy: .public)")
                CrashReport.record(error, context: ["op": "parseDeepLinkJSON"])
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
                Log.app.error("regex failed")
            }
        }
        // print("KidsTags: \(kidsTags)")
        return kidsTags
    }

    func tapped() {
        rick += 1
        if rick >= 7 {
            Log.ui.debug("easter egg: roll away")
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
    @Environment(InfoViewModel.self) private var viewModel
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
                    if let docId = item.documentId, let doc = self.viewModel.documentsById[docId] {
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
    @Environment(InfoViewModel.self) private var viewModel
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

/// Composed identity used by InfoView's .task(id:) to trigger a
/// SharedScheduleStore refresh whenever the bookmark count or the conferences
/// list changes. Hashable so SwiftUI can use it as a task identity.
private struct SharedScheduleRefreshKey: Hashable {
    let bookmarkCount: Int
    let confCount: Int
}
