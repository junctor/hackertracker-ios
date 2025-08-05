//
//  SettingsView.swift
//  hackertracker
//
//  Created by Seth W Law on 6/6/22.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var selected: SelectedConference
    @EnvironmentObject var viewModel: InfoViewModel
    @EnvironmentObject var theme: Theme
    @AppStorage("showNews") var showNews: Bool = true
    
    var body: some View {
        NavigationStack {
            if let emergId = viewModel.conference?.emergencyDocId, emergId > 0, let doc = viewModel.documents.first(where: {$0.id == emergId}) {
                NavigationLink(destination: DocumentView(title_text: doc.title, body_text: doc.body, color: ThemeColors.red, systemImage: "exclamationmark.triangle.fill")) {
                    CardView(systemImage: "exclamationmark.triangle.fill", text: doc.title, color: ThemeColors.red, subtitle: "Tap for more details")
                        .frame(height: 40)
                        .cornerRadius(0)
                }
            }
            ScrollView {
                Text("Settings")
                    .font(.title)
                Divider()
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
            .analyticsScreen(name: "SettingsView")
        }
    }
}

struct EasterEggSettingsView: View {
    @EnvironmentObject var viewModel: InfoViewModel
    @AppStorage("easterEgg") var easterEgg: Bool = false
    
    var body: some View {
        VStack(alignment: .leading) {
                Toggle("Easter Eggs", isOn: $easterEgg)
                    .onChange(of: easterEgg) { value in
                        print("SettingsView: Changing to easterEgg = \(value)")
                        viewModel.easterEgg = value
                    }
        }
        .padding(5)
        Divider()
    }
}

struct NotificationSettingsView: View {
    @EnvironmentObject var viewModel: InfoViewModel
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
                NavigationLink(destination: DocumentView(title_text: "About", body_text: "# HackerTracker (iOS)\n#### Version \(v1) Build \(v2)\nHackerTracker is a conference scheduling application \n\n## Developers\n * l4wke - [X (@sethlaw)](https://x.com/sethlaw) | [GitHub](https://github.com/sethlaw)\n * derail - [Github](https://github.com/cak)\n * advice - [X (@_advice_dog)](https://x.com/_advice_dog)\n\n## Data Wrangler\n * aNullValue - [@aNullValue@defcon.social](https://defcon.social/@anullvalue)\n")) {
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
    @EnvironmentObject var viewModel: InfoViewModel
    @AppStorage("showNews") var showNews: Bool = true
    
    var body: some View {
        VStack(alignment: .leading) {
                Toggle("News on Home Screen", isOn: $showNews)
                    .onChange(of: showNews) { value in
                        print("SettingsView: Changing to showNews = \(value)")
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
                    .onChange(of: showMerchInfo) { value in
                        print("SettingsView: Changing to showMerchInfo = \(value)")
                    }
                Text("Show the merchandise information link on the merch list")
                    .font(.caption)
        }
        .padding(5)
        Divider()
    }
}

struct ShowPastEventsSettingsView: View {
    @EnvironmentObject var viewModel: InfoViewModel
    @AppStorage("showPastEvents") var showPastEvents: Bool = true
    
    var body: some View {
        VStack(alignment: .leading) {
            Toggle("Show Past Events", isOn: $showPastEvents)
                .onChange(of: showPastEvents) { value in
                    print("SettingsView: Changing to showPastEvents = \(value)")
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
    @EnvironmentObject var viewModel: InfoViewModel
    @AppStorage("showConflictAlert") var showConflictAlert: Bool = true
    
    var body: some View {
        VStack(alignment: .leading) {
            Toggle("Show Schedule Conflict Alert", isOn: $showConflictAlert)
                .onChange(of: showConflictAlert) { value in
                    print("SettingsView: Changing to showConflictAlert = \(value)")
                }
            Text("Show the conflict alert icon on the schedule")
                .font(.caption)
        }
        .padding(5)
        Divider()
    }
}

struct LightModeSettingsView: View {
    @EnvironmentObject var viewModel: InfoViewModel
    @AppStorage("lightMode") var lightMode: Bool = false
    @AppStorage("colorMode") var colorMode: Bool = false
    @EnvironmentObject var theme: Theme

    var body: some View {
        VStack(alignment: .leading) {
            Toggle("Enable Light Mode", isOn: $lightMode)
                .onChange(of: lightMode) { value in
                    print("SettingsView: Changing to lightMode = \(value)")
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
                .onChange(of: colorMode) { value in
                    print("SettingsView: Changing to lightMode = \(value)")
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
        Divider()
    }
    
}

struct ShowLocaltimeSettingsView: View {
    @EnvironmentObject var viewModel: InfoViewModel
    @AppStorage("showLocaltime") var showLocaltime: Bool = false
    @AppStorage("show24hourtime") var show24hourtime: Bool = true
    let dfu = DateFormatterUtility.shared

    var body: some View {
        VStack(alignment: .leading) {
            Toggle("Show Local Timezone", isOn: $showLocaltime)
                .onChange(of: showLocaltime) { value in
                    print("SettingsView: Changing to showLocaltime = \(value)")
                    // viewModel.showLocaltime = value
                    if value {
                        dfu.update(tz: TimeZone.current)
                    } else {
                        dfu.update(tz: TimeZone(identifier: viewModel.conference?.timezone ?? "America/Los_Angeles"))
                    }
                }
            Text("Show event times in current localtime instead of conference time")
                .font(.caption)
        }
        .padding(5)
        Divider()
        VStack(alignment: .leading) {
            Toggle("Show 24 Hour Time", isOn: $show24hourtime)
                .onChange(of: show24hourtime) { value in
                    print("SettingsView: Changing to show24hourtime = \(value)")
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
