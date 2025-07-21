//
//  ContentView.swift
//  hackertracker
//
//  Created by Seth W Law on 5/2/22.
//

import CoreData
import FirebaseFirestore
import FirebaseAnalytics
import SwiftUI

class SelectedConference: ObservableObject {
    @Published var code = "INIT"
}

class GoToButton: ObservableObject, Equatable {
    static func == (lhs: GoToButton, rhs: GoToButton) -> Bool {
        lhs.val == rhs.val
    }
    @Published var val: Bool = false
}

class ToTop: GoToButton {}
class ToBottom: GoToButton {}
class ToCurrent: GoToButton {}
class ToNext: GoToButton {}

struct ContentView: View {
    @AppStorage("conferenceCode") var conferenceCode: String = "INIT"
    @AppStorage("launchScreen") var launchScreen: String = "Main"
    @AppStorage("showHidden") var showHidden: Bool = false
    @AppStorage("showLocaltime") var showLocaltime: Bool = false
    @AppStorage("showNews") var showNews: Bool = true
    @AppStorage("lightMode") var lightMode: Bool = false
    @AppStorage("colorMode") var colorMode: Bool = false
    @AppStorage("easterEgg") var easterEgg: Bool = false

    @StateObject var selected = SelectedConference()
    @StateObject var viewModel = InfoViewModel()
    @StateObject var consViewModel = ConferencesViewModel()
    @StateObject var theme = Theme()
    @StateObject private var toTop = ToTop()
    @StateObject private var toBottom = ToBottom()
    @StateObject private var toCurrent = ToCurrent()
    @StateObject private var toNext = ToNext()
    @StateObject var filters = Filters(filters:[])
    @State private var tabSelection = 1
    // @State private var tappedMainTwice = false
    // @State private var tappedScheduleTwice = false
    @State private var info = UUID()
    @State private var schedule = UUID()
    @State private var isInit: Bool = false
    @State private var scheduleView = ScheduleView(tagIds: [])

    var body: some View {
        if viewModel.conference != nil {
            TabView(selection: $tabSelection) {
                InfoView(tabSelection: $tabSelection)
                    .tabItem {
                        Image(systemName: "house")
                        // Text("Info")
                    }
                    .tag(1)
                    .id(info)
                    .preferredColorScheme(theme.colorScheme)
                scheduleView
                    .tabItem {
                        Image(systemName: "calendar")
                        // Text("Main")
                    }
                    .tag(2)
                    .id(schedule)
                    .preferredColorScheme(theme.colorScheme)
                MapView()
                    .tabItem {
                        Image(systemName: "map")
                        // Text("Maps")
                    }
                    .tag(3)
                    .preferredColorScheme(theme.colorScheme)
                SettingsView()
                    .tabItem {
                        Image(systemName: "gearshape")
                        // Text("Settings")
                    }
                    .tag(4)
                    .preferredColorScheme(theme.colorScheme)
            }
            .task {
                if #available(iOS 15.0, *) {
                    let tabBarAppearance: UITabBarAppearance = .init()
                    tabBarAppearance.configureWithDefaultBackground()
                    UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
                }
                print("ContentView: selectedCode: \(selected.code)")
                print("ContentView: launchScreen: \(launchScreen)")
                switch launchScreen {
                case "Maps":
                    self.tabSelection = 3
                case "Schedule":
                    self.tabSelection = 2
                default:
                    self.tabSelection = 1
                }
                viewModel.showNews = showNews
                viewModel.easterEgg = easterEgg
                if let con = viewModel.conference {
                    showLocaltime ? DateFormatterUtility.shared.update(tz: TimeZone.current) : DateFormatterUtility.shared.update(tz: TimeZone(identifier: con.timezone ?? "America/Los_Angeles"))
                }

                // viewModel.fetchData(code: selected.code)
            }
            .environmentObject(selected)
            .environmentObject(viewModel)
            .environmentObject(theme)
            .environmentObject(consViewModel)
            .environmentObject(toTop)
            .environmentObject(toBottom)
            .environmentObject(toCurrent)
            .environmentObject(toNext)
            .environmentObject(filters)
            .analyticsScreen(name: "ContentView")
        } else {
            if conferenceCode == "INIT" {
                ConferencesView()
                    .preferredColorScheme(theme.colorScheme)
                    .environmentObject(selected)
                    .environmentObject(viewModel)
                    .environmentObject(consViewModel)
                    .environmentObject(theme)
                    .environmentObject(filters)
            } else {
                _04View(message: "Loading", show404: false).preferredColorScheme(theme.colorScheme)
                    .task {
                        print("ContentView: Selected Conference \(selected.code), Conference Code: \(conferenceCode)")
                        if selected.code != conferenceCode {
                            print("ContentView: Switching to conference from AppStorage - \(conferenceCode)")
                            selected.code = conferenceCode
                        }
                        self.viewModel.fetchData(code: conferenceCode)
                        self.consViewModel.fetchConferences(hidden: showHidden)
                    }
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Text("Content View Preview")
        /* Group {
             ContentView(settings: Settings()).environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
         } */
    }
}
