//
//  ContentView.swift
//  hackertracker
//
//  Created by Seth W Law on 5/2/22.
//

import Combine
import CoreData
import FirebaseFirestore
import FirebaseAnalytics
import SwiftUI

class SelectedConference: ObservableObject {
    @Published var code = "INIT"
}

/// Scroll commands the schedule (and any other scrollable list) can
/// respond to. Sent through ScrollCommandBus below.
enum ScrollCommand {
    case top, bottom, current, next
}

/// Fire-and-forget command bus for scroll-to actions. Intentionally an
/// ObservableObject with NO @Published properties: `objectWillChange`
/// never fires, so sending a command doesn't invalidate every view
/// holding the bus via @EnvironmentObject — consumers subscribe with
/// `.onReceive(bus.subject)` and scroll their own proxy. This replaces
/// the old ToTop/ToBottom/ToCurrent/ToNext published-Bool handshake,
/// which re-evaluated the whole schedule body twice per command.
final class ScrollCommandBus: ObservableObject {
    let subject = PassthroughSubject<ScrollCommand, Never>()
    func send(_ command: ScrollCommand) {
        subject.send(command)
    }
}

struct ContentView: View {
    @AppStorage(AppStorageKeys.conferenceCode) var conferenceCode: String = "INIT"
    @AppStorage(AppStorageKeys.launchScreen) var launchScreen: String = "Main"
    @AppStorage(AppStorageKeys.showHidden) var showHidden: Bool = false
    @AppStorage(AppStorageKeys.showLocaltime) var showLocaltime: Bool = false
    @AppStorage(AppStorageKeys.showNews) var showNews: Bool = true
    @AppStorage(AppStorageKeys.lightMode) var lightMode: Bool = false
    @AppStorage(AppStorageKeys.colorMode) var colorMode: Bool = false
    @AppStorage(AppStorageKeys.easterEgg) var easterEgg: Bool = false

    @StateObject var selected = SelectedConference()
    @State private var viewModel = InfoViewModel()
    @State private var consViewModel = ConferencesViewModel()
    /// App-wide theme manager: palettes, typography, light/dark
    /// preference, and the colorful-mode card palette. The single
    /// theming source of truth (the legacy `Theme` ObservableObject
    /// is gone). Injected here at the ContentView level, same as the
    /// other long-lived stores.
    @State private var themeManager = ThemeManager()
    @StateObject private var scrollBus = ScrollCommandBus()
    @StateObject var filters = Filters(filters:[])
    /// Independent filter set for the Speakers list — selections here
    /// don't bleed into Schedule / All Content.
    @StateObject var speakerFilters = SpeakerFiltersStore()
    /// Independent filter set for the Merch list. Holds the user's
    /// selected sizes. Hoisted from ProductsView's @State so the
    /// selection survives tab switches (and now cold launches too).
    @StateObject var merchFilters = MerchFiltersStore()
    @State private var tabSelection = 1
    @State private var isInit: Bool = false
    @State private var showingEmergencySheet = false

    var body: some View {
        if viewModel.conference != nil {
            TabView(selection: $tabSelection) {
                InfoView(tabSelection: $tabSelection)
                    .tabItem {
                        // Easter Egg: swap the SF Symbol "house" for the
                        // bespoke beezle_icon asset when the user has
                        // Easter Eggs enabled in Settings. .renderingMode
                        // template + the system's tab bar tinting keep
                        // the icon looking like a native tab item.
                        if easterEgg {
                            Image("beezle_icon")
                                .renderingMode(.template)
                        } else {
                            Image(systemName: "house")
                        }
                        // Text("Info")
                    }
                    .tag(1)
                    .preferredColorScheme(themeManager.preferredColorScheme)
                ScheduleView(tagIds: [])
                    .tabItem {
                        Image(systemName: "calendar")
                        // Text("Main")
                    }
                    .tag(2)
                    .preferredColorScheme(themeManager.preferredColorScheme)
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
                    .preferredColorScheme(themeManager.preferredColorScheme)
                SettingsView()
                    .tabItem {
                        Image(systemName: "gearshape")
                        // Text("Settings")
                    }
                    .tag(4)
                    .preferredColorScheme(themeManager.preferredColorScheme)
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

                // Age gate: query the declared age range up front so
                // restricted content is filtered before the user browses.
                await viewModel.refreshAgeGate()

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
            .environment(themeManager)
            .environment(consViewModel)
            .environmentObject(scrollBus)
            .environmentObject(filters)
            .environmentObject(speakerFilters)
            .environmentObject(merchFilters)
            // Themes: set the default body font for the entire tab
            // tree. Any Text() that doesn't explicitly call .font()
            // inherits this — so card labels, schedule rows, settings
            // labels, product detail text, etc. all pick up the
            // theme's body font (system / monospaced / rounded)
            // automatically.
            .font(themeManager.bodyFont)
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
                    .preferredColorScheme(themeManager.preferredColorScheme)
                    .environmentObject(selected)
                    .environment(viewModel)
                    .environment(consViewModel)
                    .environment(themeManager)
                    .environmentObject(filters)
                    .environmentObject(speakerFilters)
                    .environmentObject(merchFilters)
            } else {
                _04View(message: "Loading", show404: false).preferredColorScheme(themeManager.preferredColorScheme)
                    .preferredColorScheme(themeManager.preferredColorScheme)
                    .environmentObject(selected)
                    .environment(viewModel)
                    .environment(consViewModel)
                    .environment(themeManager)
                    .environmentObject(filters)
                    .environmentObject(speakerFilters)
                    .environmentObject(merchFilters)
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
    @AppStorage(AppStorageKeys.easterEgg) var easterEgg: Bool = false
    @AppStorage(AppStorageKeys.colorMode) var colorMode: Bool = false
    /// User-tunable peak opacity of the breathing watermark. Floor at
    /// 0.05 so we never persist a fully-invisible setting that looks
    /// like the feature is broken; ceiling at 1.0 if the user wants
    /// the ghost solid-on at peak.
    @AppStorage(AppStorageKeys.easterEggMaxOpacity) var easterEggMaxOpacity: Double = 0.20
    /// Period of the sine-wave pulse, in seconds. 0 turns the pulse
    /// off entirely — the watermark stays held at peak opacity.
    @AppStorage(AppStorageKeys.easterEggPeriod) var easterEggPeriod: Double = 12.0
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if easterEgg {
            TimelineView(.animation(minimumInterval: 1.0/30.0)) { context in
                let t = context.date.timeIntervalSinceReferenceDate
                // Opacity. easterEggPeriod == 0 holds the ghost at
                // peak; otherwise we draw a sine wave from 0 up to
                // easterEggMaxOpacity with the user-chosen period.
                let peak = max(0.05, min(easterEggMaxOpacity, 1.0))
                let opacity: Double = {
                    if easterEggPeriod <= 0 { return peak }
                    let phase = sin(t * (.pi * 2 / easterEggPeriod))
                    return (phase + 1) / 2 * peak
                }()
                // Hue cycle, period ~12s. Only consulted when colorMode
                // is on; otherwise we fall back to system primary.
                let hue = (t.truncatingRemainder(dividingBy: 12.0)) / 12.0
                // Eye-detail preservation:
                //  - Rainbow path uses .colorMultiply with a fully-saturated
                //    hue. White body * hue = hue, slightly-darker eye
                //    pixels * hue = darker hue — value differences survive.
                //  - Dark mode without rainbow: leave the image as-is
                //    (white silhouette on dark background).
                //  - Light mode without rainbow: .colorInvert() flips
                //    white -> black while preserving the relative shading
                //    between body and eyes. .colorMultiply(.black) here
                //    would collapse everything to one flat color and the
                //    eyes would vanish (same regression we hit before).
                Image("beezle")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 280, maxHeight: 280)
                    .opacity(opacity)
                    .applyBeezleEasterEggTint(
                        colorMode: colorMode,
                        hue: hue,
                        colorScheme: colorScheme
                    )
                    .accessibilityHidden(true)
            }
        }
    }
}

extension View {
    @ViewBuilder
    fileprivate func applyBeezleEasterEggTint(colorMode: Bool, hue: Double, colorScheme: ColorScheme) -> some View {
        if colorMode {
            self.colorMultiply(Color(hue: hue, saturation: 0.85, brightness: 1.0))
        } else if colorScheme == .light {
            self.colorInvert()
        } else {
            self
        }
    }
}
