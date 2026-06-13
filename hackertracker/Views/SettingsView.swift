//
//  SettingsView.swift
//  hackertracker
//
//  Created by Seth W Law on 6/6/22.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var selected: SelectedConference
    @Environment(InfoViewModel.self) private var viewModel
    @EnvironmentObject var theme: Theme
    @AppStorage("showNews") var showNews: Bool = true
    
    var body: some View {
        NavigationStack {
            if let emergId = viewModel.conference?.emergencyDocId, emergId > 0, let doc = viewModel.documentsById[emergId] {
                NavigationLink(destination: DocumentView(title_text: doc.title, body_text: doc.body, color: ThemeColors.red, systemImage: "exclamationmark.triangle.fill")) {
                    CardView(systemImage: "exclamationmark.triangle.fill", text: doc.title, color: ThemeColors.red, subtitle: "Tap for more details")
                        .frame(height: 40)
                        .cornerRadius(0)
                }
            }
            ScrollView {
                AboutSettingsView()
                HStack {
                    NavigationLink(destination: ConferencesView()) {
                        Image(systemName: "list.bullet")
                            .padding(5)
                        VStack(alignment: .leading) {
                            Text("Select Conference")
                                .bold()
                            Text("(\(viewModel.conference?.name ?? selected.code))")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(5)
                        Image(systemName: "chevron.right")
                            .padding(5)
                    }
                    .frame(maxWidth: .infinity)
                }
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(5)
                Divider()
                StartScreenSettingsView()
                ShowLocaltimeSettingsView()
                ShowPastEventsSettingsView()
                ShowNewsSettingsView()
                NotificationSettingsView()
                EasterEggSettingsView()
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .iPadReadableContent()
            .analyticsScreen(name: "SettingsView")
        }
    }
}

struct EasterEggSettingsView: View {
    @Environment(InfoViewModel.self) private var viewModel
    @AppStorage("easterEgg") var easterEgg: Bool = false
    
    var body: some View {
        VStack(alignment: .leading) {
                Toggle("Easter Eggs", isOn: $easterEgg)
                    .onChange(of: easterEgg) { _, value in 
                        Log.ui.debug("easterEgg=\(value)")
                        viewModel.easterEgg = value
                    }
        }
        .padding(5)
        Divider()
    }
}

struct NotificationSettingsView: View {
    @Environment(InfoViewModel.self) private var viewModel
    @AppStorage("notifyAt") var notifyAt: Int = 20
    @State private var showingAlert = false

    var body: some View {
        Text("Notifications")
            .font(.headline)
        VStack(alignment: .leading) {
            Stepper("Before Event: \(notifyAt)", value: $notifyAt, in: 0...60)
                Text("Notification time in minutes")
                    .font(.caption)
        }
        .padding(5)
        HStack {
            Button {
                showingAlert = true
            } label: {
                Text("Remove all notifications")
                Image(systemName: "trash")
            }
            .alert("Are you sure", isPresented: $showingAlert) {
                Button("Yes") {
                    NotificationUtility.removeAllNotifications()
                }
                Button("No", role: .cancel) { }
            }
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding(5)
        .background(ThemeColors.red)
        .cornerRadius(5)
        Divider()
        ShowConflictAlertView()
        Divider()
        ShowMerchInfoSettingsView()
        Divider()
    }
}

struct AboutSettingsView: View {
    
    var body: some View {
        HStack {
            if let v1 = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String, let v2 = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                NavigationLink(destination: DocumentView(title_text: "About", body_text: "# HackerTracker (iOS)\n#### Version \(v1) Build \(v2)\nHackerTracker is a conference scheduling application \n\n## Developers\n * l4wke - [X (@sethlaw)](https://x.com/sethlaw) | [GitHub](https://github.com/sethlaw)\n * derail - [Github](https://github.com/cak)\n * advice - [X (@_advice_dog)](https://x.com/_advice_dog)\n\n## Data Wrangler\n * aNullValue - [@aNullValue@defcon.social](https://defcon.social/@anullvalue)\n", showInlineTitle: false)) {
                    Image(systemName: "info.circle")
                        .padding(5)
                    VStack(alignment: .leading) {
                        Text("About")
                            .bold()
                        Text("\(v1) (\(v2))")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(5)
                    Image(systemName: "chevron.right")
                        .padding(5)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .foregroundColor(.primary)
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(5)
        Divider()
    }
}

struct ShowNewsSettingsView: View {
    @Environment(InfoViewModel.self) private var viewModel
    @AppStorage("showNews") var showNews: Bool = true
    
    var body: some View {
        VStack(alignment: .leading) {
                Toggle("News on Home Screen", isOn: $showNews)
                    .onChange(of: showNews) { _, value in 
                        Log.ui.debug("showNews=\(value)")
                        viewModel.showNews = value
                    }
                Text("Show the most recent news article on the home screen")
                    .font(.caption)
        }
        .padding(5)
        Divider()
    }
}

struct ShowMerchInfoSettingsView: View {
    @AppStorage("showMerchInfo") var showMerchInfo: Bool = true
    
    var body: some View {
        VStack(alignment: .leading) {
                Toggle("Merch Info on Merchandise Screen", isOn: $showMerchInfo)
                    .onChange(of: showMerchInfo) { _, value in 
                        Log.ui.debug("showMerchInfo=\(value)")
                    }
                Text("Show the merchandise information link on the merch list")
                    .font(.caption)
        }
        .padding(5)
        Divider()
    }
}

struct ShowPastEventsSettingsView: View {
    @Environment(InfoViewModel.self) private var viewModel
    @AppStorage("showPastEvents") var showPastEvents: Bool = true
    
    var body: some View {
        VStack(alignment: .leading) {
            Toggle("Show Past Events", isOn: $showPastEvents)
                .onChange(of: showPastEvents) { _, value in 
                    Log.ui.debug("showPastEvents=\(value)")
                    viewModel.showPastEvents = value
                }
            Text("Show or hide past events in the conference schedule")
                .font(.caption)
        }
        .padding(5)
        Divider()
    }
}

struct ShowConflictAlertView: View {
    @Environment(InfoViewModel.self) private var viewModel
    @AppStorage("showConflictAlert") var showConflictAlert: Bool = true
    
    var body: some View {
        VStack(alignment: .leading) {
            Toggle("Show Schedule Conflict Alert", isOn: $showConflictAlert)
                .onChange(of: showConflictAlert) { _, value in 
                    Log.ui.debug("showConflictAlert=\(value)")
                }
            Text("Show the conflict alert icon on the schedule")
                .font(.caption)
        }
        .padding(5)
        Divider()
    }
}

struct LightModeSettingsView: View {
    @Environment(InfoViewModel.self) private var viewModel
    @AppStorage("lightMode") var lightMode: Bool = false
    @AppStorage("colorMode") var colorMode: Bool = false
    @EnvironmentObject var theme: Theme

    var body: some View {
        VStack(alignment: .leading) {
            Toggle("Enable Light Mode", isOn: $lightMode)
                .onChange(of: lightMode) { _, value in 
                    Log.ui.debug("lightMode=\(value)")
                    if value {
                        theme.colorScheme = .light
                    } else {
                        theme.colorScheme = .dark
                    }
                }
        }
        .padding(5)
        Divider()
        VStack(alignment: .leading) {
            Toggle("Enable Colorful Mode", isOn: $colorMode)
                .onChange(of: colorMode) { _, value in 
                    Log.ui.debug("colorMode=\(value)")
                    //colorMode = value
                }
        }
        .padding(5)
        Divider()
    }
}

struct StartScreenSettingsView: View {
    @AppStorage("launchScreen") var launchScreen: String = "Main"
    let startScreens = ["Main", "Schedule", "Maps"]

    var body: some View {
        LightModeSettingsView()
        VStack(alignment: .leading) {
            Text("Start Screen")
            Picker("Start Screen", selection: $launchScreen) {
                ForEach(startScreens, id: \.self) {
                    Text($0)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(5)  // Match the .padding(5) every other settings row uses.
        Divider()
    }
    
}

struct ShowLocaltimeSettingsView: View {
    @Environment(InfoViewModel.self) private var viewModel
    @AppStorage("showLocaltime") var showLocaltime: Bool = false
    @AppStorage("show24hourtime") var show24hourtime: Bool = true
    let dfu = DateFormatterUtility.shared

    /// The IANA identifier of the timezone the schedule currently renders in.
    /// When `showLocaltime` is on we use the device's current zone; otherwise
    /// we fall back to the active conference's `timezone` field. If neither
    /// is available (e.g. conference field is empty), show the device zone.
    private var currentTimezoneDisplay: String {
        if showLocaltime {
            return TimeZone.current.identifier
        }
        if let confTZ = viewModel.conference?.timezone, !confTZ.isEmpty {
            return confTZ
        }
        return TimeZone.current.identifier
    }

    var body: some View {
        VStack(alignment: .leading) {
            Toggle("Show Local Timezone", isOn: $showLocaltime)
                .onChange(of: showLocaltime) { _, value in 
                    Log.ui.debug("showLocaltime=\(value)")
                    // viewModel.showLocaltime = value
                    if value {
                        dfu.update(tz: TimeZone.current)
                    } else {
                        ClockService.apply(conference: viewModel.conference, showLocaltime: false)
                    }
                }
            // Polish: surface the currently-active timezone so the user can
            // see what the toggle actually resolves to. Mirrors how
            // ClockService.resolveTimeZone decides which zone to apply:
            // showLocaltime ON  -> device-current
            // showLocaltime OFF -> conference's timezone (or device-current fallback)
            HStack(spacing: 4) {
                Image(systemName: "clock")
                Text(currentTimezoneDisplay)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            // Polish: same vertical breathing room above the description as
            // the description has from the Toggle above the clock row.
            .padding(.bottom, 6)
            Text("Show event times in current localtime instead of conference time")
                .font(.caption)
        }
        .padding(5)
        Divider()
        VStack(alignment: .leading) {
            Toggle("Show 24 Hour Time", isOn: $show24hourtime)
                .onChange(of: show24hourtime) { _, value in 
                    Log.ui.debug("show24hourtime=\(value)")
                }
            Text("Show event times in 24 hour time (13:00) instead of 12 hour time (1:00 PM)")
                .font(.caption)
        }
        .padding(5)
        Divider()
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
