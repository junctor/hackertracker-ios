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
    @State private var viewModel = InfoViewModel()
    @State private var consViewModel = ConferencesViewModel()
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
    @State private var showingEmergencySheet = false

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
                        // Animate the SF Symbol while map assets are
                        // downloading in the background so users get
                        // immediate feedback that work is happening.
                        Image(systemName: viewModel.mapsLoading ? "map.fill" : "map")
                            .symbolEffect(.variableColor.iterative.reversing, options: .repeating, isActive: viewModel.mapsLoading)
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
            // Easter-egg overlay: faint, fading beezle behind the UI.
            // Only renders when easterEgg is on. With colorMode also on,
            // it cycles rainbow hues. allowsHitTesting(false) keeps the
            // tab bar and content fully interactive.
            .overlay(BeezleEasterEggOverlay().allowsHitTesting(false))
            .task {
                if #available(iOS 15.0, *) {
                    let tabBarAppearance: UITabBarAppearance = .init()
                    tabBarAppearance.configureWithDefaultBackground()
                    UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
                }
                Log.app.debug("ContentView selectedCode=\(selected.code, privacy: .public) launchScreen=\(launchScreen, privacy: .public)")
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

                // Phase 5d: ATT prompt. Wait briefly so the system alert
                // doesn't obscure first-frame UI on cold launch. ATT only
                // shows the system prompt on first launch; later launches
                // honor the cached decision without re-prompting.
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                await TrackingPermission.requestIfNeeded()

                // viewModel.fetchData(code: selected.code)
            }
            .task(id: "\(viewModel.conference?.timezone ?? "nil")|\(showLocaltime)") {
                // Phase 4 follow-up (corrected): the TabView only mounts AFTER
                // viewModel.conference != nil. .onChange(of:) only fires on
                // subsequent changes -- never on the value present at mount --
                // so the previous attempt never triggered on initial load and
                // the schedule rendered in device-current time despite
                // showLocaltime being off.
                //
                // .task(id:) fires both on first appearance AND whenever the
                // identity composed of (conference.timezone, showLocaltime)
                // changes. Result: the active timezone is applied at app
                // launch, on conference switch, and on showLocaltime toggle.
                ClockService.apply(conference: viewModel.conference, showLocaltime: showLocaltime)
            }
            .environmentObject(selected)
            .environment(viewModel)
            .environmentObject(theme)
            .environment(consViewModel)
            .environmentObject(toTop)
            .environmentObject(toBottom)
            .environmentObject(toCurrent)
            .environmentObject(toNext)
            .environmentObject(filters)
            .analyticsScreen(name: "ContentView")
        } else {
            if conferenceCode == "INIT" {
                // Polish: wrap in NavigationStack so ConferencesView's
                // .navigationTitle / .toolbar / .toolbarBackground actually
                // render. The other call sites (NavigationLink from InfoView,
                // SettingsView, 404View) already provide a NavigationStack so
                // they don't need this wrap.
                NavigationStack {
                    ConferencesView()
                }
                    .preferredColorScheme(theme.colorScheme)
                    .environmentObject(selected)
                    .environment(viewModel)
                    .environment(consViewModel)
                    .environmentObject(theme)
                    .environmentObject(filters)
            } else {
                _04View(message: "Loading", show404: false).preferredColorScheme(theme.colorScheme)
                    .preferredColorScheme(theme.colorScheme)
                    .environmentObject(selected)
                    .environment(viewModel)
                    .environment(consViewModel)
                    .environmentObject(theme)
                    .environmentObject(filters)
                    .task {
                        Log.app.debug("ContentView selected=\(selected.code, privacy: .public) stored=\(conferenceCode, privacy: .public)")
                        if selected.code != conferenceCode {
                            Log.app.info("ContentView switching to conference \(conferenceCode, privacy: .public)")
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

/// Animated beezle watermark, enabled by the Easter Egg toggle in
/// Settings. Uses TimelineView for a continuous animation tick rather
/// than .animation().repeatForever() so we don't have to manage @State
/// flip-flops -- the closure recomputes opacity + hue from the current
/// time on each frame.
///
/// When easterEgg AND colorMode are both on, the silhouette cycles
/// through the full hue spectrum once every 12s; with just easterEgg
/// it tints to the system primary so it adapts to light/dark mode.
private struct BeezleEasterEggOverlay: View {
    @AppStorage("easterEgg") var easterEgg: Bool = false
    @AppStorage("colorMode") var colorMode: Bool = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if easterEgg {
            TimelineView(.animation(minimumInterval: 1.0/30.0)) { context in
                let t = context.date.timeIntervalSinceReferenceDate
                // Sine wave for opacity, period ~6s, range 0.05..0.25.
                let phase = sin(t * (.pi * 2 / 6.0))
                let opacity = 0.05 + (phase + 1) / 2 * 0.20
                // Hue cycle, period ~12s. Only consulted when colorMode
                // is on; otherwise we fall back to system primary.
                let hue = (t.truncatingRemainder(dividingBy: 12.0)) / 12.0
                Image("beezle")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 280, maxHeight: 280)
                    .opacity(opacity)
                    .colorMultiply(
                        colorMode
                            ? Color(hue: hue, saturation: 0.85, brightness: 1.0)
                            : (colorScheme == .light ? .black : .white)
                    )
                    .accessibilityHidden(true)
            }
        }
    }
}
