//
//  SettingsView.swift
//  hackertracker
//
//  Created by Seth W Law on 6/6/22.
//

import MarkdownUI
import SwiftUI

enum SettingsIPadSheet: Identifiable {
    case about, conferences
    var id: Int { hashValue }
}

struct SettingsView: View {
    @EnvironmentObject var selected: SelectedConference
    @Environment(InfoViewModel.self) private var viewModel
    @EnvironmentObject var theme: Theme
    @AppStorage("showNews") var showNews: Bool = true
    @State private var iPadSheet: SettingsIPadSheet?

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
                // About + conference picker always span the full width
                // — they read as headers and don't fit naturally into a
                // 2-column grid row.
                VStack(spacing: 0) {
                    AboutSettingsView(iPadAction: IPadAdaptive.isIPad ? { iPadSheet = .about } : nil)
                    selectConferenceRow
                    Divider()
                }
                if IPadAdaptive.isIPad {
                    // iPad: explicit 2-column HStack. Each panel is
                    // wrapped in VStack(spacing: 0) { ... } so its
                    // multi-Item @ViewBuilder body counts as ONE cell.
                    // (Subviews like LightModeSettingsView return a
                    // TupleView of VStack + Divider + VStack + Divider,
                    // which a LazyVGrid would explode into separate
                    // grid items.)
                    HStack(alignment: .top, spacing: 16) {
                        VStack(spacing: 12) {
                            VStack(spacing: 0) { LightModeSettingsView() }
                            VStack(spacing: 0) { ShowLocaltimeSettingsView() }
                            VStack(spacing: 0) { ShowPastEventsSettingsView() }
                            VStack(spacing: 0) { ShowNewsSettingsView() }
                            Spacer(minLength: 0)
                        }
                        .frame(maxWidth: .infinity, alignment: .top)
                        VStack(spacing: 12) {
                            VStack(spacing: 0) { StartScreenPickerView() }
                            VStack(spacing: 0) { NotificationSettingsView() }
                            VStack(spacing: 0) { AISummarySettingsView() }
                            VStack(spacing: 0) { ShowCustomEventsSettingsView() }
                            VStack(spacing: 0) { EasterEggSettingsView() }
                            Spacer(minLength: 0)
                        }
                        .frame(maxWidth: .infinity, alignment: .top)
                    }
                    .padding(.horizontal, 12)
                } else {
                    LightModeSettingsView()
                    StartScreenPickerView()
                    ShowLocaltimeSettingsView()
                    ShowPastEventsSettingsView()
                    ShowNewsSettingsView()
                    NotificationSettingsView()
                    AISummarySettingsView()
                    ShowCustomEventsSettingsView()
                    EasterEggSettingsView()
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            // iPad no longer needs the readable-column cap on Settings —
            // the 2-column grid utilizes the full width directly. iPhone
            // sees the same single-column flow either way.
            .analyticsScreen(name: "SettingsView")
        }
        .fullScreenCover(item: $iPadSheet) { sheet in
            NavigationStack {
                Group {
                    switch sheet {
                    case .about:
                        if let v1 = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                           let v2 = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                            AboutView(marketingVersion: v1, buildVersion: v2)
                        }
                    case .conferences:
                        ConferencesView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { iPadSheet = nil }
                    }
                }
            }
        }
    }
    @ViewBuilder private var selectConferenceRow: some View {
        HStack {
            if IPadAdaptive.isIPad {
                Button {
                    iPadSheet = .conferences
                } label: {
                    conferenceRowLabel
                }
                .frame(maxWidth: .infinity)
            } else {
                NavigationLink(destination: ConferencesView()) {
                    conferenceRowLabel
                }
                .frame(maxWidth: .infinity)
            }
        }
        .foregroundColor(.primary)
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(5)
    }

    @ViewBuilder private var conferenceRowLabel: some View {
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

}

struct EasterEggSettingsView: View {
    @Environment(InfoViewModel.self) private var viewModel
    @AppStorage("easterEgg") var easterEgg: Bool = false
    @AppStorage("easterEggMaxOpacity") var easterEggMaxOpacity: Double = 0.20
    @AppStorage("easterEggPeriod") var easterEggPeriod: Double = 12.0

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Easter Eggs", isOn: $easterEgg)
                .onChange(of: easterEgg) { _, value in
                    Log.ui.debug("easterEgg=\(value)")
                    viewModel.easterEgg = value
                }
            if easterEgg {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Peak Opacity")
                        Spacer()
                        Text(String(format: "%.0f%%", easterEggMaxOpacity * 100))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    // Floor at 0.05 so accidental drag to zero doesn't
                    // make the feature look broken; ceiling at 1.0.
                    Slider(value: $easterEggMaxOpacity, in: 0.05...1.0, step: 0.05)
                    Text("How bright the background beezle gets at the peak of its pulse.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Pulse Period")
                        Spacer()
                        Text(easterEggPeriod <= 0
                             ? "off"
                             : String(format: "%.0fs", easterEggPeriod))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    // 0 = hold peak; otherwise a full sine cycle every
                    // N seconds. Cap at 60 because anything slower than
                    // a minute reads as "off" anyway.
                    Stepper("Period",
                            value: $easterEggPeriod,
                            in: 0.0...60.0,
                            step: 1.0)
                        .labelsHidden()
                    Text("Seconds for a full fade in + out. 0 holds the ghost steady at the peak opacity.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
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
    /// On iPad, the parent SettingsView passes a closure that presents
    /// AboutView as a sheet instead of pushing it on the NavigationStack
    /// (which would replace the whole settings screen). On iPhone this
    /// is nil and the row falls back to the standard NavigationLink push.
    var iPadAction: (() -> Void)? = nil

    var body: some View {
        HStack {
            if let v1 = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String, let v2 = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                if let iPadAction {
                    Button(action: iPadAction) {
                        aboutRowLabel(v1: v1, v2: v2)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    NavigationLink(destination: AboutView(marketingVersion: v1, buildVersion: v2)) {
                        aboutRowLabel(v1: v1, v2: v2)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .foregroundColor(.primary)
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(5)
        Divider()
    }

    @ViewBuilder private func aboutRowLabel(v1: String, v2: String) -> some View {
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
}

/// Build provenance — git commit / branch / dirty / build date, stamped
/// at build time by the "Stamp build info" Run Script phase. Lets a user
/// confirm which public commit the installed build came from.
struct BuildInfo {
    let commit: String
    let commitShort: String
    let branch: String
    let dirty: Bool
    let buildDate: String

    static let repoURL = "https://github.com/junctor/hackertracker-ios"

    static let current: BuildInfo? = {
        guard let url = Bundle.main.url(forResource: "BuildInfo", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String]
        else { return nil }
        return BuildInfo(
            commit: plist["GitCommit"] ?? "unknown",
            commitShort: plist["GitCommitShort"] ?? "unknown",
            branch: plist["GitBranch"] ?? "unknown",
            dirty: (plist["GitDirty"] ?? "false") == "true",
            buildDate: plist["BuildDate"] ?? "unknown"
        )
    }()

    var commitURL: URL? {
        guard commit != "unknown" else { return nil }
        return URL(string: "\(BuildInfo.repoURL)/commit/\(commit)")
    }
}

struct AboutView: View {
    let marketingVersion: String
    let buildVersion: String
    @Environment(\.openURL) private var openURL

    private static let aboutBody = """
# HackerTracker (iOS)

HackerTracker is a conference scheduling application.

## Developers
 * l4wke - [X (@sethlaw)](https://x.com/sethlaw) | [GitHub](https://github.com/sethlaw)
 * derail - [Github](https://github.com/cak)
 * advice - [X (@_advice_dog)](https://x.com/_advice_dog)

## Data Wrangler
 * aNullValue - [@aNullValue@defcon.social](https://defcon.social/@anullvalue)

## License

HackerTracker iOS is licensed under the [GNU General Public License v3.0](https://github.com/junctor/hackertracker-ios/blob/main/LICENSE). You are free to use, modify, and redistribute it under the terms of that license.
"""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                versionHeader

                Markdown(AboutView.aboutBody)

                Divider()
                privacySection

                if let info = BuildInfo.current {
                    Divider()
                    buildInfoSection(info)
                }
            }
            .padding()
            .iPadReadableContent()
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var versionHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Version \(marketingVersion)")
                .font(.title3).bold()
            Text("Build \(buildVersion)")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private var privacySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "hand.raised")
                Text("Privacy & Tracking")
                    .font(.headline)
            }

            Text("What this app does and doesn’t collect. The full disclosure mirrors the docs/privacy.md page in the public repo.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            NavigationLink(destination: DocumentView(
                title_text: PrivacyDoc.title,
                body_text: PrivacyDoc.body,
                color: nil,
                systemImage: "hand.raised",
                showInlineTitle: false
            )) {
                Label("Read the full disclosure", systemImage: "doc.text")
                    .frame(maxWidth: .infinity)
                    .padding(10)
                    .background(Color.accentColor.opacity(0.15))
                    .cornerRadius(8)
            }
        }
    }

    @ViewBuilder
    private func buildInfoSection(_ info: BuildInfo) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: info.dirty ? "checkmark.seal.trianglebadge.exclamationmark" : "checkmark.seal")
                    .foregroundStyle(info.dirty ? .orange : .primary)
                Text("Build provenance")
                    .font(.headline)
            }

            Text("Stamped at build time. Tap **View on GitHub** to confirm this build came from a specific public commit — if the page 404s, this build was not produced from a public commit on the official repo.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 10) {
                row("Commit", info.commit, mono: true)
                row("Short", info.commitShort, mono: true)
                row("Branch", info.branch)
                row("Working tree", info.dirty ? "dirty (uncommitted changes at build time)" : "clean")
                row("Build date (UTC)", info.buildDate)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)

            if info.dirty {
                Label("This build was produced from a working copy with uncommitted changes. It does not correspond to a single public commit.", systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundStyle(.orange)
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
            }

            if let url = info.commitURL {
                Button {
                    openURL(url)
                } label: {
                    Label("View on GitHub", systemImage: "arrow.up.right.square")
                        .frame(maxWidth: .infinity)
                        .padding(10)
                        .background(Color.accentColor.opacity(0.15))
                        .cornerRadius(8)
                }
            }

            Button {
                UIPasteboard.general.string = """
                version:    \(marketingVersion) (\(buildVersion))
                commit:     \(info.commit)
                short:      \(info.commitShort)
                branch:     \(info.branch)
                dirty:      \(info.dirty)
                buildDate:  \(info.buildDate)
                """
            } label: {
                Label("Copy build info", systemImage: "doc.on.doc")
                    .frame(maxWidth: .infinity)
                    .padding(10)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
            }
        }
    }

    @ViewBuilder
    private func row(_ label: String, _ value: String, mono: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(mono ? .system(.footnote, design: .monospaced) : .body)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
    var body: some View {
        // Compatibility wrapper: legacy callers got LightMode + the
        // Start Screen picker stacked together. New code should call
        // LightModeSettingsView and StartScreenPickerView separately.
        VStack(spacing: 0) {
            LightModeSettingsView()
            StartScreenPickerView()
        }
    }
}

struct StartScreenPickerView: View {
    @AppStorage("launchScreen") var launchScreen: String = "Main"
    let startScreens = ["Main", "Schedule", "Maps"]

    var body: some View {
        VStack(alignment: .leading) {
            Text("Start Screen")
            Picker("Start Screen", selection: $launchScreen) {
                ForEach(startScreens, id: \.self) {
                    Text($0)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(5)
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

/// Toggle for the on-device Apple Intelligence summary feature.
/// Visibility rules:
///   - Hidden entirely on older iOS / unsupported builds
///     (AISummaryAvailability.isPossiblyAvailable == false), so we
///     don't tease a feature the user can't ever turn on.
///   - Shown but disabled when the OS supports the framework but the
///     model isn't currently available (e.g. still downloading,
///     low-power mode). Caption explains why.
///   - Fully interactive otherwise.
struct AISummarySettingsView: View {
    @AppStorage("aiSummaries") var aiSummaries: Bool = false

    var body: some View {
        if AISummaryAvailability.isPossiblyAvailable {
            VStack(alignment: .leading, spacing: 4) {
                Toggle("AI Summaries", isOn: $aiSummaries)
                    .disabled(!AISummaryAvailability.isSupported)
                    .onChange(of: aiSummaries) { _, value in
                        Log.ui.debug("aiSummaries=\(value)")
                    }
                Text("Show one-sentence summaries of talk descriptions, generated on-device by Apple Intelligence. Summaries are cached and only generated for descriptions longer than 100 characters.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !AISummaryAvailability.isSupported {
                    Text("Apple Intelligence isn\u{2019}t available on this device right now.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(5)
            Divider()
        }
    }
}

/// Settings row that lets the user hide custom events en masse.
/// Hidden by EventsView.scheduleEvents — synthesizer skips when this
/// is false. Defaults true: opting in to create custom events implies
/// wanting them visible.
struct ShowCustomEventsSettingsView: View {
    @AppStorage("showCustomEvents") var showCustomEvents: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Toggle("Custom Events on Schedule", isOn: $showCustomEvents)
            Text("Hide your custom events from the conference schedule. They\u{2019}re still stored locally and synced to your other devices.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(5)
        Divider()
    }
}
