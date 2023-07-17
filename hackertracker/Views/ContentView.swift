//
//  ContentView.swift
//  hackertracker
//
//  Created by Seth W Law on 5/2/22.
//

import CoreData
import FirebaseFirestoreSwift
import SwiftUI

class SelectedConference: ObservableObject {
    @Published var code = "INIT"
}

struct ContentView: View {
    @AppStorage("conferenceCode") var conferenceCode: String = "INIT"
    @AppStorage("launchScreen") var launchScreen: String = "Main"
    @AppStorage("showHidden") var showHidden: Bool = false
    @AppStorage("showLocaltime") var showLocaltime: Bool = false
    @AppStorage("showNews") var showNews: Bool = true
    @AppStorage("lightMode") var lightMode: Bool = false

    @StateObject var selected = SelectedConference()
    @StateObject var viewModel = InfoViewModel()

    @State private var tabSelection = 1
    @State private var isInit: Bool = false

    private var theme = Theme()

    var body: some View {
        if viewModel.conference != nil {
            TabView(selection: $tabSelection) {
                InfoView()
                    .tabItem {
                        Image(systemName: "house")
                        // Text("Info")
                    }
                    .tag(1)
                    .preferredColorScheme(theme.colorScheme)
                ScheduleView(tagIds: [])
                    .tabItem {
                        Image(systemName: "calendar")
                        // Text("Main")
                    }
                    .tag(2)
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
            .onAppear {
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
                if let con = viewModel.conference {
                    showLocaltime ? DateFormatterUtility.shared.update(tz: TimeZone.current) : DateFormatterUtility.shared.update(tz: TimeZone(identifier: con.timezone ?? "America/Los_Angeles"))
                }

                // viewModel.fetchData(code: selected.code)
            }
            .environmentObject(selected)
            .environmentObject(viewModel)
            .environmentObject(theme)
        } else {
            if conferenceCode == "INIT" {
                ConferencesView()
                    .preferredColorScheme(theme.colorScheme)
                    .environmentObject(selected)
                    .environmentObject(viewModel)
            } else {
                _04View(message: "Loading", show404: false).preferredColorScheme(.dark)
                    .onAppear {
                        print("ContentView: Selected Conference \(selected.code), Conference Code: \(conferenceCode)")
                        if selected.code != conferenceCode {
                            print("ContentView: Switching to conference from AppStorage - \(conferenceCode)")
                            selected.code = conferenceCode
                        }
                        self.viewModel.fetchData(code: conferenceCode)
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
