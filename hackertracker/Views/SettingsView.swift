//
//  SettingsView.swift
//  hackertracker
//
//  Created by Seth W Law on 6/6/22.
//

import MarkdownUI
import SwiftUI

enum SettingsIPadSheet: Identifiable {
    case about, conferences, theme
    var id: Int { hashValue }
}

enum IPadSheetSize {
    /// Large modal that doesn't quite reach the screen edges.
    case page
    /// Default small centered form sheet.
    case form
}

/// Card styling for Settings rows. Mirrors the schedule / content
/// cell look (themed cardSurface, 10pt corners, 8/3 outer padding)
/// so the Settings tab reads as the same card-based surface the rest
/// of the app uses instead of a flat form.
extension View {
    @ViewBuilder
    func settingsCard(_ themeManager: ThemeManager) -> some View {
        self
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(themeManager.cardSurface)
            .cornerRadius(ThemeMetrics.cardRadius)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
    }
}

extension View {
    /// Sheet sizing for iPad presentations. iOS 18+ uses the native
    /// `.presentationSizing(...)`. iOS 17 falls back to an explicit
    /// large frame for `.page` (iPad form sheets grow to fit their
    /// content's intrinsic size). `.form` is the iPad default — no
    /// modifier needed pre-iOS 18.
    ///
    /// (View extension instead of `ViewModifier` because this module
    /// has its own `Content` model that shadows the protocol's
    /// `Content` associated type — same workaround used in
    /// `iPadAdaptive.swift`.)
    @ViewBuilder
    func iPadSheetSizing(_ size: IPadSheetSize) -> some View {
        switch size {
        case .page:
            if #available(iOS 18, *) {
                self.presentationSizing(.page)
            } else {
                self
                    .frame(idealWidth: 1100, idealHeight: 1300)
                    .frame(minWidth: 900, minHeight: 1100)
            }
        case .form:
            if #available(iOS 18, *) {
                self.presentationSizing(.form)
            } else {
                self
            }
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var selected: SelectedConference
    @Environment(InfoViewModel.self) private var viewModel
    @AppStorage(AppStorageKeys.showNews) var showNews: Bool = true
    @State private var iPadSheet: SettingsIPadSheet?

    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        NavigationStack {
            if let emergId = viewModel.conference?.emergencyDocId, emergId > 0, let doc = viewModel.documentsById[emergId] {
                NavigationLink(destination: DocumentView(title_text: doc.title, body_text: doc.body, color: themeManager.danger, systemImage: "exclamationmark.triangle.fill")) {
                    CardView(systemImage: "exclamationmark.triangle.fill", text: doc.title, color: themeManager.danger, subtitle: "Tap for more details")
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
                    ThemePickerSettingsView(iPadAction: IPadAdaptive.isIPad ? { iPadSheet = .theme } : nil)
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
                            VStack(spacing: 0) { AgeVerificationSettingsView() }
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
                    AgeVerificationSettingsView()
                    ShowCustomEventsSettingsView()
                    EasterEggSettingsView()
                }
            }
            .navigationTitle("Settings")
            .themedNavTitle("Settings", themeManager)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            // iPad no longer needs the readable-column cap on Settings —
            // the 2-column grid utilizes the full width directly. iPhone
            // sees the same single-column flow either way.
            .themedBackground(themeManager)
            .analyticsScreen(name: "SettingsView")
        }
        .sheet(item: $iPadSheet) { sheet in
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
                    case .theme:
                        ThemePickerView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { iPadSheet = nil }
                    }
                }
            }
            // About wants the big page-sheet (lots of content). The
            // conference picker reads better at the default form-sheet
            // size — short list, no need to fill the screen.
            .iPadSheetSizing(sheet == .about ? .page : .form)
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
        .settingsCard(themeManager)
    }

    @ViewBuilder private var conferenceRowLabel: some View {
        Image(systemName: "list.bullet")
            .padding(5)
        VStack(alignment: .leading) {
            Text("Select Conference")
                .bold()
            Text("(\(viewModel.conference?.name ?? selected.code))")
                .font(themeManager.captionFont)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(5)
        Image(systemName: "chevron.right")
            .padding(5)
    }

}

struct EasterEggSettingsView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(InfoViewModel.self) private var viewModel
    @AppStorage(AppStorageKeys.easterEgg) var easterEgg: Bool = false
    @AppStorage(AppStorageKeys.easterEggMaxOpacity) var easterEggMaxOpacity: Double = 0.20
    @AppStorage(AppStorageKeys.easterEggPeriod) var easterEggPeriod: Double = 12.0

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
                            .font(themeManager.captionFont)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    // Floor at 0.05 so accidental drag to zero doesn't
                    // make the feature look broken; ceiling at 1.0.
                    Slider(value: $easterEggMaxOpacity, in: 0.05...1.0, step: 0.05)
                    Text("How bright the background beezle gets at the peak of its pulse.")
                        .font(themeManager.captionFont)
                        .foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Pulse Period")
                        Spacer()
                        Text(easterEggPeriod <= 0
                             ? "off"
                             : String(format: "%.0fs", easterEggPeriod))
                            .font(themeManager.captionFont)
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
                        .font(themeManager.captionFont)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .settingsCard(themeManager)
    }
}

struct NotificationSettingsView: View {
    @Environment(InfoViewModel.self) private var viewModel
    @Environment(ThemeManager.self) private var themeManager
    @AppStorage(AppStorageKeys.notifyAt) var notifyAt: Int = 20
    @State private var showingAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Notifications")
                .font(themeManager.headingFont)
            VStack(alignment: .leading) {
                Stepper("Before Event: \(notifyAt)", value: $notifyAt, in: 0...60)
                Text("Notification time in minutes")
                    .font(themeManager.captionFont)
            }
            Button {
                showingAlert = true
            } label: {
                HStack {
                    Text("Remove all notifications")
                    Image(systemName: "trash")
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(5)
                .background(themeManager.danger)
                .cornerRadius(5)
            }
            .alert("Are you sure", isPresented: $showingAlert) {
                Button("Yes") {
                    NotificationUtility.removeAllNotifications()
                }
                Button("No", role: .cancel) { }
            }
        }
        .settingsCard(themeManager)
        ShowConflictAlertView()
        ShowMerchInfoSettingsView()
    }
}

struct AboutSettingsView: View {
    /// On iPad, the parent SettingsView passes a closure that presents
    /// AboutView as a sheet instead of pushing it on the NavigationStack
    /// (which would replace the whole settings screen). On iPhone this
    /// is nil and the row falls back to the standard NavigationLink push.
    var iPadAction: (() -> Void)? = nil

    @Environment(ThemeManager.self) private var themeManager

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
        .settingsCard(themeManager)
    }

    @ViewBuilder private func aboutRowLabel(v1: String, v2: String) -> some View {
        Image(systemName: "info.circle")
            .padding(5)
        VStack(alignment: .leading) {
            Text("About")
                .bold()
            Text("\(v1) (\(v2))")
                .font(themeManager.captionFont)
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

    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                versionHeader

                Markdown(AboutView.aboutBody).themedMarkdown(themeManager)

                Divider()
                privacySection

                if let info = BuildInfo.current {
                    Divider()
                    buildInfoSection(info)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("About")
        .themedNavTitle("About", themeManager)
        .navigationBarTitleDisplayMode(.inline)
        .themedBackground(themeManager)
    }

    private var versionHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Version \(marketingVersion)")
                .font(themeManager.title3Font).bold()
            Text("Build \(buildVersion)")
                .font(themeManager.calloutFont)
                .foregroundStyle(.secondary)
        }
    }

    private var privacySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "hand.raised")
                Text("Privacy & Tracking")
                    .font(themeManager.headingFont)
            }

            Text("What this app does and doesn’t collect. The full disclosure mirrors the docs/privacy.md page in the public repo.")
                .font(themeManager.footnoteFont)
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
                    .background(themeManager.accent.opacity(0.15))
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
                    .font(themeManager.headingFont)
            }

            Text("Stamped at build time. Tap **View on GitHub** to confirm this build came from a specific public commit — if the page 404s, this build was not produced from a public commit on the official repo.")
                .font(themeManager.footnoteFont)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 10) {
                row("Commit", info.commit, mono: true)
                row("Short", info.commitShort, mono: true)
                row("Branch", info.branch)
                row("Working tree", info.dirty ? "dirty (uncommitted changes at build time)" : "clean")
                row("Build date (UTC)", info.buildDate)
            }
            .padding()
            .background(themeManager.cardSurface)
            .cornerRadius(8)

            if info.dirty {
                Label("This build was produced from a working copy with uncommitted changes. It does not correspond to a single public commit.", systemImage: "exclamationmark.triangle.fill")
                    .font(themeManager.footnoteFont)
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
                        .background(themeManager.accent.opacity(0.15))
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
                    .background(themeManager.cardSurface)
                    .cornerRadius(8)
            }
        }
    }

    @ViewBuilder
    private func row(_ label: String, _ value: String, mono: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(themeManager.captionFont)
                .foregroundStyle(.secondary)
            Text(value)
                .font(mono ? .system(.footnote, design: .monospaced) : themeManager.bodyFont)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}


struct ShowNewsSettingsView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(InfoViewModel.self) private var viewModel
    @AppStorage(AppStorageKeys.showNews) var showNews: Bool = true
    
    var body: some View {
        VStack(alignment: .leading) {
                Toggle("News on Home Screen", isOn: $showNews)
                    .onChange(of: showNews) { _, value in 
                        Log.ui.debug("showNews=\(value)")
                        viewModel.showNews = value
                    }
                Text("Show the most recent news article on the home screen")
                    .font(themeManager.captionFont)
        }
        .settingsCard(themeManager)
    }
}

struct ShowMerchInfoSettingsView: View {
    @Environment(ThemeManager.self) private var themeManager
    @AppStorage(AppStorageKeys.showMerchInfo) var showMerchInfo: Bool = true
    
    var body: some View {
        VStack(alignment: .leading) {
                Toggle("Merch Info on Merchandise Screen", isOn: $showMerchInfo)
                    .onChange(of: showMerchInfo) { _, value in 
                        Log.ui.debug("showMerchInfo=\(value)")
                    }
                Text("Show the merchandise information link on the merch list")
                    .font(themeManager.captionFont)
        }
        .settingsCard(themeManager)
    }
}

struct ShowPastEventsSettingsView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(InfoViewModel.self) private var viewModel
    @AppStorage(AppStorageKeys.showPastEvents) var showPastEvents: Bool = true
    
    var body: some View {
        VStack(alignment: .leading) {
            Toggle("Show Past Events", isOn: $showPastEvents)
                .onChange(of: showPastEvents) { _, value in 
                    Log.ui.debug("showPastEvents=\(value)")
                    viewModel.showPastEvents = value
                }
            Text("Show or hide past events in the conference schedule")
                .font(themeManager.captionFont)
        }
        .settingsCard(themeManager)
    }
}

struct ShowConflictAlertView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(InfoViewModel.self) private var viewModel
    @AppStorage(AppStorageKeys.showConflictAlert) var showConflictAlert: Bool = true
    
    var body: some View {
        VStack(alignment: .leading) {
            Toggle("Show Schedule Conflict Alert", isOn: $showConflictAlert)
                .onChange(of: showConflictAlert) { _, value in 
                    Log.ui.debug("showConflictAlert=\(value)")
                }
            Text("Show the conflict alert icon on the schedule")
                .font(themeManager.captionFont)
        }
        .settingsCard(themeManager)
    }
}

struct LightModeSettingsView: View {
    @Environment(InfoViewModel.self) private var viewModel
    @Environment(ThemeManager.self) private var themeManager
    @AppStorage(AppStorageKeys.lightMode) var lightMode: Bool = false
    @AppStorage(AppStorageKeys.colorMode) var colorMode: Bool = false

    var body: some View {
        VStack(alignment: .leading) {
            Toggle("Enable Light Mode", isOn: $lightMode)
                .onChange(of: lightMode) { _, value in
                    Log.ui.debug("lightMode=\(value)")
                    // The @AppStorage binding drives the Toggle UI; the
                    // ThemeManager stored property is what the rest of
                    // the app observes via preferredColorScheme.
                    themeManager.setLightMode(value)
                }
        }
        .settingsCard(themeManager)
        VStack(alignment: .leading) {
            Toggle("Enable Colorful Mode", isOn: $colorMode)
                .onChange(of: colorMode) { _, value in
                    Log.ui.debug("colorMode=\(value)")
                }
        }
        .settingsCard(themeManager)
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
    @Environment(ThemeManager.self) private var themeManager
    @AppStorage(AppStorageKeys.launchScreen) var launchScreen: String = "Main"
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
        .settingsCard(themeManager)
    }
}

struct ShowLocaltimeSettingsView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(InfoViewModel.self) private var viewModel
    @AppStorage(AppStorageKeys.showLocaltime) var showLocaltime: Bool = false
    @AppStorage(AppStorageKeys.show24hourtime) var show24hourtime: Bool = true
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
            .font(themeManager.captionFont)
            .foregroundStyle(.secondary)
            // Polish: same vertical breathing room above the description as
            // the description has from the Toggle above the clock row.
            .padding(.bottom, 6)
            Text("Show event times in current localtime instead of conference time")
                .font(themeManager.captionFont)
        }
        .settingsCard(themeManager)
        VStack(alignment: .leading) {
            Toggle("Show 24 Hour Time", isOn: $show24hourtime)
                .onChange(of: show24hourtime) { _, value in
                    Log.ui.debug("show24hourtime=\(value)")
                }
            Text("Show event times in 24 hour time (13:00) instead of 12 hour time (1:00 PM)")
                .font(themeManager.captionFont)
        }
        .settingsCard(themeManager)
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
    @Environment(ThemeManager.self) private var themeManager
    @AppStorage(AppStorageKeys.aiSummaries) var aiSummaries: Bool = false
    /// Hidden gate for AI-generated speaker bios. Off by default and
    /// the toggle only becomes visible after a 7-tap chord on the
    /// "AI Summaries" row (or stays visible if already on, so users
    /// can switch it back off without re-discovering the chord).
    @AppStorage(AppStorageKeys.speakerAISummaries) var speakerAISummaries: Bool = false
    /// Tap-counter chord. Transient — resets on view rebuild, which
    /// is fine because revealing the row is a one-time discovery.
    @State private var aiTapCount: Int = 0
    @State private var showSpeakerToggle: Bool = false

    var body: some View {
        if AISummaryAvailability.isPossiblyAvailable {
            VStack(alignment: .leading, spacing: 4) {
                Toggle("AI Summaries", isOn: $aiSummaries)
                    .disabled(!AISummaryAvailability.isSupported)
                    .onChange(of: aiSummaries) { _, value in
                        Log.ui.debug("aiSummaries=\(value)")
                    }
                    // 7-tap chord on the row label reveals the hidden
                    // Speaker bios toggle below. contentShape on the
                    // VStack ensures taps on the label area register
                    // — the Toggle's switch handles its own taps.
                    .contentShape(Rectangle())
                    .onTapGesture {
                        aiTapCount += 1
                        if aiTapCount >= 7 {
                            showSpeakerToggle = true
                            aiTapCount = 0
                        }
                    }
                Text("Show one-sentence summaries of talk descriptions, generated on-device by Apple Intelligence. Summaries are cached and only generated for descriptions longer than 100 characters.")
                    .font(themeManager.captionFont)
                    .foregroundStyle(.secondary)
                if !AISummaryAvailability.isSupported {
                    Text("Apple Intelligence isn\u{2019}t available on this device right now.")
                        .font(themeManager.captionFont)
                        .foregroundStyle(.tertiary)
                }

                // Hidden secondary toggle. Visible when (a) revealed
                // by the chord this session, or (b) the user already
                // turned it on previously — so they can disable it
                // without having to re-tap the chord.
                if showSpeakerToggle || speakerAISummaries {
                    Divider()
                        .padding(.vertical, 4)
                    Toggle("Speaker bios (experimental)", isOn: $speakerAISummaries)
                        .disabled(!aiSummaries || !AISummaryAvailability.isSupported)
                        .onChange(of: speakerAISummaries) { _, value in
                            Log.ui.debug("speakerAISummaries=\(value)")
                        }
                    Text("Also summarize speaker bios on the Speakers list when no job title is provided. Bios shorter than 100 characters render verbatim either way.")
                        .font(themeManager.captionFont)
                        .foregroundStyle(.secondary)
                }
            }
            .settingsCard(themeManager)
            .onAppear {
                // Surface the toggle immediately on appear if the
                // flag's already true (the chord only matters when
                // it's currently off).
                if speakerAISummaries { showSpeakerToggle = true }
            }
        }
    }
}

/// Settings row showing Declared Age Range verification status, with a
/// re-verify button on iOS 26+. On older iOS the row explains the
/// feature is unavailable rather than showing a dead button.
struct AgeVerificationSettingsView: View {
    @Environment(InfoViewModel.self) private var viewModel
    @Environment(ThemeManager.self) private var themeManager
    @State private var verifying = false

    private var statusText: String {
        if #available(iOS 26, *) {
            if let lower = viewModel.ageGate.lowerBound {
                return "Verified: \(lower)+"
            }
            return "Not verified"
        }
        return "Unavailable on this iOS"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Age Verification")
                .font(themeManager.headingFont)
            Text(statusText)
                .font(themeManager.captionFont)
                .foregroundStyle(.secondary)
            if #available(iOS 26, *) {
                Button {
                    verifying = true
                    Task {
                        await viewModel.refreshAgeGate(forcePrompt: true)
                        verifying = false
                    }
                } label: {
                    Text(verifying ? "Verifying…" : "Verify Age")
                }
                .disabled(verifying)
                Text("Age-restricted content is shown based on your device's declared age range.")
                    .font(themeManager.captionFont)
                    .foregroundStyle(.secondary)
            }
        }
        .settingsCard(themeManager)
    }
}

/// Settings row that lets the user hide custom events en masse.
/// Hidden by EventsView.scheduleEvents — synthesizer skips when this
/// is false. Defaults true: opting in to create custom events implies
/// wanting them visible.
struct ShowCustomEventsSettingsView: View {
    @Environment(ThemeManager.self) private var themeManager
    @AppStorage(AppStorageKeys.showCustomEvents) var showCustomEvents: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Toggle("Custom Events on Schedule", isOn: $showCustomEvents)
            Text("Hide your custom events from the conference schedule. They\u{2019}re still stored locally and synced to your other devices.")
                .font(themeManager.captionFont)
                .foregroundStyle(.secondary)
        }
        .settingsCard(themeManager)
    }
}

// MARK: - Theme picker

struct ThemePickerSettingsView: View {
    @Environment(ThemeManager.self) private var themeManager
    /// iPad shortcut: parent SettingsView presents ThemePickerView in
    /// a form sheet instead of pushing.
    var iPadAction: (() -> Void)? = nil

    var body: some View {
        HStack {
            if let iPadAction {
                Button(action: iPadAction) { themeRowLabel }
                    .frame(maxWidth: .infinity)
            } else {
                NavigationLink(destination: ThemePickerView()) { themeRowLabel }
                    .frame(maxWidth: .infinity)
            }
        }
        .foregroundColor(.primary)
        .settingsCard(themeManager)
    }

    @ViewBuilder private var themeRowLabel: some View {
        Image(systemName: "paintbrush")
            .padding(5)
        VStack(alignment: .leading) {
            Text("Theme")
                .bold()
            Text(themeManager.current.displayName)
                .font(themeManager.captionFont)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(5)
        Image(systemName: "chevron.right")
            .padding(5)
    }
}

struct ThemePickerView: View {
    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(ThemeRegistry.all) { theme in
                    Button {
                        themeManager.setTheme(theme.id)
                    } label: {
                        themeRow(theme)
                    }
                    .buttonStyle(.plain)
                }
                Text("Themes change card backgrounds, accent colors, and typography across the app. Pick one and the rest of the UI updates immediately.")
                    .font(themeManager.captionFont)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
                    .padding(.top, 8)
            }
            .padding()
        }
        .navigationTitle("Theme")
        .themedNavTitle("Theme", themeManager)
        .navigationBarTitleDisplayMode(.inline)
        .themedBackground(themeManager)
    }

    /// One row per registered theme. Each row previews the theme's
    /// OWN cardSurface + typography so the picker doubles as a
    /// live look-book.
    @ViewBuilder
    private func themeRow(_ theme: AppTheme) -> some View {
        let isActive = theme.id == themeManager.current.id
        HStack(spacing: 12) {
            HStack(spacing: 6) {
                swatch(theme.palette.cardSurface.auto)
                swatch(theme.palette.accent.auto)
                swatch(theme.palette.danger.auto)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(theme.displayName)
                    .font(theme.typography.heading)
                    .foregroundStyle(theme.palette.textPrimary.auto)
                Text(isActive ? "Active" : "Tap to apply")
                    .font(themeManager.captionFont)
                    .foregroundStyle(theme.palette.textSecondary.auto)
            }
            Spacer()
            if isActive {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(themeManager.success)
                    .font(themeManager.title3Font)
            }
        }
        .padding()
        .background(theme.palette.cardSurface.auto)
        .overlay(
            RoundedRectangle(cornerRadius: ThemeMetrics.cardRadius)
                .stroke(isActive ? themeManager.success : Color.primary.opacity(0.08),
                        lineWidth: isActive ? 2 : 0.5)
        )
        .cornerRadius(ThemeMetrics.cardRadius)
    }

    private func swatch(_ color: Color) -> some View {
        Circle()
            .fill(color)
            .frame(width: 22, height: 22)
            .overlay(Circle().stroke(Color.primary.opacity(0.15), lineWidth: 0.5))
    }
}
