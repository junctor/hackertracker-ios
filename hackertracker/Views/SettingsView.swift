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
        NavigationView {
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
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(5)
                Divider()
                StartScreenSettingsView()
                ShowLocaltimeSettingsView()
                ShowPastEventsSettingsView()
                ShowNewsSettingsView()
            }
            .padding(10)
        }
    }
}

struct AboutSettingsView: View {
    
    var body: some View {
        HStack {
            if let v1 = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String, let v2 = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                NavigationLink(destination: DocumentView(title_text: "About", body_text: "# Hackertracker (iOS)\n#### Version \(v1) Build \(v2)\nHackertracker is a conference scheduling application \n\n## Developers\n * [l4wke](https://twitter.com/sethlaw)\n * [cak](https://github.com/cak)")) {
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
        .foregroundColor(.white)
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
        VStack {
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

struct ShowPastEventsSettingsView: View {
    @EnvironmentObject var viewModel: InfoViewModel
    @AppStorage("showPastEvents") var showPastEvents: Bool = true
    
    var body: some View {
        VStack {
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

struct StartScreenSettingsView: View {
    @AppStorage("launchScreen") var launchScreen: String = "Main"
    let startScreens = ["Main", "Schedule", "Maps"]

    var body: some View {
        VStack {
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
    let dfu = DateFormatterUtility.shared

    var body: some View {
        VStack {
            Toggle("Show Local Timezone", isOn: $showLocaltime)
                .onChange(of: showLocaltime) { value in
                    print("SettingsView: Changing to showLocaltime = \(value)")
                    viewModel.showLocaltime = value
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
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
