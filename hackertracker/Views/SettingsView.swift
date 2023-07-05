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
    @AppStorage("launchScreen") var launchScreen: String = "Main"
    @AppStorage("showLocaltime") var showLocaltime: Bool = false
    let startScreens = ["Main", "Schedule", "Maps"]
    let dfu = DateFormatterUtility.shared

    var theme = Theme()

    var body: some View {
        ScrollView {
            Text("Settings")
                .font(.headline)
            Divider()
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
                    .frame(maxWidth: .infinity)
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
        .padding(10)
        .onAppear {
            print("SettingsView: Current launchscreen is: \(launchScreen)")
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
