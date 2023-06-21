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
    @Published var code = "DEFCON30"
}

struct ContentView: View {
    @AppStorage("conferenceCode") var conferenceCode: String = "DEFCON30"
    @StateObject private var viewModel = ContentViewModel()

    @ObservedObject var selected = SelectedConference()

    // @FirestoreQuery(collectionPath: "conferences") var conferences: [Conference]

    // @State var conference: Conference?
    // @State private var viewModel = ConferencesViewModel()

    private var colorScheme: ColorScheme = .dark

    var body: some View {
        if let _ = viewModel.conference {
            NavigationView {
                TabView {
                    InfoView()
                        .tabItem {
                            Image(systemName: "house")
                            // Text("Info")
                        }
                        .tag(3)
                        .preferredColorScheme(colorScheme)
                    ScheduleView()
                        .tabItem {
                            Image(systemName: "calendar")
                            // Text("Main")
                        }
                        .tag(1)
                        .preferredColorScheme(colorScheme)
                    MapView()
                        .tabItem {
                            Image(systemName: "map")
                            // Text("Maps")
                        }
                        .tag(2)
                        .preferredColorScheme(colorScheme)
                    SettingsView()
                        .tabItem {
                            Image(systemName: "gearshape")
                            // Text("Settings")
                        }
                        .tag(4)
                        .preferredColorScheme(colorScheme)
                }
            }
            .onAppear {
                
                if #available(iOS 15.0, *) {
                    let tabBarAppearance: UITabBarAppearance = .init()
                    tabBarAppearance.configureWithDefaultBackground()
                    UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
                }
            }
            .environmentObject(selected)
        } else {
            Text("loading")
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
