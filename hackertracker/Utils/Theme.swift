//
//  Theme.swift
//  hackertracker
//
//  Created by caleb on 6/17/22.
//

import SwiftUI

// The legacy `Theme` ObservableObject (colorScheme flag + impure
// carousel() color cycler + unused Futura ThemeFont) is gone — its
// responsibilities folded into ThemeManager below: lightMode /
// preferredColorScheme for the app-wide scheme, carouselColor(index:)
// for the colorful-mode card palette.

enum ThemeColors {
    static let pink = hexSwiftUIColor(hex: "#c16784")
    static let blue = hexSwiftUIColor(hex: "#326295")
    static let green = hexSwiftUIColor(hex: "#71cc98")
    static let drkGreen = hexSwiftUIColor(hex: "#4b9560")
    static let red = hexSwiftUIColor(hex: "#c04c36")
    static let gray = hexSwiftUIColor(hex: "#2D2D2D")

    /// Default fill for "standout" buttons and cards. A hair darker than
    /// `.systemGray6` in light mode and a hair lighter in dark mode so
    /// these surfaces pop a little more against the base background
    /// without crossing into `.systemGray5` territory.
    /// - light: ≈ #EBEBF0  (systemGray6 #F2F2F7 nudged darker)
    /// - dark:  ≈ #26262A  (systemGray6 #1C1C1E nudged lighter)
    static let cardSurface = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 38/255,  green: 38/255,  blue: 42/255,  alpha: 1)
            : UIColor(red: 235/255, green: 235/255, blue: 240/255, alpha: 1)
    })

    /// Mid-tone text color used by row "secondary" content — speaker
    /// subtitle, AI summary line, event-titles line, chip labels.
    /// Brighter than `.gray` (~50%) but still clearly subordinate to
    /// the row title. Built off `.primary` so it adapts to theme.
    static let muted = Color.primary.opacity(0.75)
}

// MARK: - AppTheme infrastructure
//
// Themes are value types. Each theme bundles a palette of semantic
// color tokens (cardSurface, accent, danger, etc.) and a typography
// set (heading, body, caption, monospace, largeTitle). Each token
// carries both a light and dark variant; `DualColor.resolve(_:)` picks
// the right one based on the current ColorScheme.
//
// Views read tokens via the injected `ThemeManager` — see PR 2 for
// the call-site migration. PR 1 (this file) only adds plumbing; no
// rendering changes.

/// Pair of Color values, one for each system appearance.
struct DualColor: Hashable {
    let light: Color
    let dark: Color
    func resolve(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? dark : light
    }

    /// Self-resolving Color that picks the right variant based on the
    /// active system appearance — no `@Environment(\.colorScheme)`
    /// read needed at the call site. Useful when threading colorScheme
    /// through every view would be noisier than the win.
    var auto: Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(self.dark)
                : UIColor(self.light)
        })
    }

    static let cardSurface = DualColor(
        light: Color(red: 235/255, green: 235/255, blue: 240/255),
        dark:  Color(red: 38/255,  green: 38/255,  blue: 42/255)
    )
}

/// Semantic color tokens. Adding a token here is the single-source
/// change to make a new themable surface — every concrete theme then
/// supplies its own DualColor for that token.
struct ThemePalette: Hashable {
    let background: DualColor    // base screen background — shows below cards
    let cardSurface: DualColor   // standout-button and detail-card fill
    let accent: DualColor         // primary tinted action color
    let success: DualColor        // active, selected, positive affordances
    let danger: DualColor         // warnings, conflicts, destructive
    let textPrimary: DualColor    // headings + body text
    let textSecondary: DualColor  // metadata + captions
    let divider: DualColor        // section + row separators
    let chipBackground: DualColor // tag chips / pill backgrounds (when not theming per-tag color)
}

/// Font roles. Each theme supplies a Font for each role. The default
/// theme uses the system fonts; alternate themes can swap in
/// rounded / serif / monospaced / custom families.
struct ThemeTypography: Hashable {
    let largeTitle: Font
    let title: Font        // .title — section headers, prominent body text
    let title2: Font       // .title2 — sub-section headers
    let title3: Font       // .title3 — tertiary headers
    let heading: Font      // .headline — list cell titles, settings labels
    let subheadline: Font  // .subheadline — secondary metadata under a heading
    let body: Font
    let caption: Font
    let monospace: Font
}

/// A complete theme: palette + typography + identity.
struct AppTheme: Identifiable, Hashable {
    let id: String          // stable persistence key, e.g. "default"
    let displayName: String // shown in the Settings picker
    let palette: ThemePalette
    let typography: ThemeTypography
}

extension AppTheme {
    /// The baseline theme — matches every existing color / font in
    /// the app exactly so flipping to it from the registry produces
    /// no visual change.
    static let `default` = AppTheme(
        id: "default",
        displayName: "Default",
        palette: ThemePalette(
            background: DualColor(
                light: Color(.systemBackground),
                dark:  Color(.systemBackground)
            ),
            cardSurface: .cardSurface,
            // .systemBlue is a dynamic UIColor whose dark variant is
            // brighter than ThemeColors.blue (#326295). Using it here
            // bumps Default-dark accent-on-cardSurface contrast from
            // 2.38 (WCAG FAIL) to ~4.8 (PASS).
            accent: DualColor(
                light: Color(.systemBlue),
                dark:  Color(.systemBlue)
            ),
            success: DualColor(
                light: Color(.systemGreen),
                dark:  Color(.systemGreen)
            ),
            danger: DualColor(
                light: ThemeColors.red,
                dark:  ThemeColors.red
            ),
            textPrimary: DualColor(
                light: .black,
                dark:  .white
            ),
            textSecondary: DualColor(
                light: Color(.secondaryLabel),
                dark:  Color(.secondaryLabel)
            ),
            divider: DualColor(
                light: Color(.separator),
                dark:  Color(.separator)
            ),
            chipBackground: .cardSurface
        ),
        typography: ThemeTypography(
            largeTitle:  .largeTitle,
            title:       .title,
            title2:      .title2,
            title3:      .title3,
            heading:     .headline,
            subheadline: .subheadline,
            body:        .body,
            caption:     .caption,
            monospace:   .system(.body, design: .monospaced)
        )
    )
}

extension AppTheme {
    /// Terminal vibe: green-tinted surfaces, neon-green accent,
    /// monospaced body text. Dark variant leans deep-forest; light
    /// variant is a paler institutional green so the theme reads in
    /// either appearance.
    static let hackerGreen = AppTheme(
        id: "hackerGreen",
        displayName: "Hacker Green",
        palette: ThemePalette(
            background: DualColor(
                light: Color(red: 240/255, green: 245/255, blue: 240/255), // #F0F5F0 — faint green-white
                dark:  Color(red: 5/255,   green: 12/255,  blue: 6/255)    // #050C06 — near-black with green warmth
            ),
            cardSurface: DualColor(
                light: Color(red: 232/255, green: 240/255, blue: 232/255), // #E8F0E8
                dark:  Color(red: 15/255,  green: 32/255,  blue: 16/255)   // #0F2010
            ),
            accent: DualColor(
                light: Color(red: 0/255,   green: 140/255, blue: 50/255),  // #008C32 (readable on white)
                dark:  Color(red: 0/255,   green: 255/255, blue: 65/255)   // #00FF41 (matrix green)
            ),
            success: DualColor(
                light: Color(red: 0/255,   green: 140/255, blue: 50/255),  // #008C32
                dark:  Color(red: 0/255,   green: 255/255, blue: 65/255)   // #00FF41
            ),
            danger: DualColor(
                light: ThemeColors.red,
                dark:  ThemeColors.red
            ),
            textPrimary: DualColor(
                light: .black,
                dark:  Color(red: 200/255, green: 255/255, blue: 200/255)  // soft green-white
            ),
            textSecondary: DualColor(
                light: Color(red: 60/255,  green: 90/255,  blue: 60/255),
                dark:  Color(red: 120/255, green: 180/255, blue: 120/255)
            ),
            divider: DualColor(
                light: Color(.separator),
                dark:  Color(red: 40/255, green: 80/255, blue: 40/255)
            ),
            chipBackground: DualColor(
                light: Color(red: 220/255, green: 235/255, blue: 220/255),
                dark:  Color(red: 25/255,  green: 50/255,  blue: 28/255)
            )
        ),
        typography: ThemeTypography(
            // Full terminal aesthetic: every text role uses bundled
            // JetBrains Mono so the theme reads as one unbroken voice
            // from largeTitle to caption. `relativeTo:` keeps Dynamic
            // Type scaling intact.
            largeTitle:  Font.custom("JetBrainsMono-Bold",    size: 34, relativeTo: .largeTitle),
            title:       Font.custom("JetBrainsMono-Bold",    size: 28, relativeTo: .title),
            title2:      Font.custom("JetBrainsMono-Bold",    size: 22, relativeTo: .title2),
            title3:      Font.custom("JetBrainsMono-Bold",    size: 20, relativeTo: .title3),
            heading:     Font.custom("JetBrainsMono-Regular", size: 17, relativeTo: .headline),
            subheadline: Font.custom("JetBrainsMono-Regular", size: 15, relativeTo: .subheadline),
            body:        Font.custom("JetBrainsMono-Regular", size: 17, relativeTo: .body),
            caption:     Font.custom("JetBrainsMono-Regular", size: 12, relativeTo: .caption),
            monospace:   Font.custom("JetBrainsMono-Regular", size: 17, relativeTo: .body)
        )
    )

    /// Synthwave: muted purple cards, neon-magenta accent, rounded
    /// sans-serif typography. Reads as warm-dark in dark mode and
    /// gentle lavender in light mode.
    static let synthwave = AppTheme(
        id: "synthwave",
        displayName: "Synthwave",
        palette: ThemePalette(
            background: DualColor(
                light: Color(red: 245/255, green: 240/255, blue: 248/255), // #F5F0F8 — faint lavender-white
                dark:  Color(red: 12/255,  green: 6/255,   blue: 22/255)   // #0C0616 — near-black warm purple
            ),
            cardSurface: DualColor(
                light: Color(red: 242/255, green: 232/255, blue: 245/255), // #F2E8F5
                dark:  Color(red: 42/255,  green: 26/255,  blue: 64/255)   // #2A1A40
            ),
            accent: DualColor(
                light: Color(red: 200/255, green: 0/255,   blue: 150/255), // deep magenta
                dark:  Color(red: 255/255, green: 64/255,  blue: 200/255)  // neon magenta
            ),
            success: DualColor(
                light: Color(red: 200/255, green: 0/255,   blue: 150/255), // deep magenta
                dark:  Color(red: 255/255, green: 64/255,  blue: 200/255)  // neon magenta
            ),
            danger: DualColor(
                light: ThemeColors.red,
                dark:  ThemeColors.red
            ),
            textPrimary: DualColor(
                light: .black,
                dark:  Color(red: 250/255, green: 230/255, blue: 255/255)
            ),
            textSecondary: DualColor(
                light: Color(red: 90/255,  green: 60/255,  blue: 100/255),
                dark:  Color(red: 200/255, green: 170/255, blue: 220/255)
            ),
            divider: DualColor(
                light: Color(.separator),
                dark:  Color(red: 90/255, green: 60/255, blue: 130/255)
            ),
            chipBackground: DualColor(
                light: Color(red: 230/255, green: 215/255, blue: 240/255),
                dark:  Color(red: 60/255,  green: 38/255,  blue: 92/255)
            )
        ),
        typography: ThemeTypography(
            // Major Mono Display ships Regular only — its display feel
            // carries every text role; the previous `.bold()` chains
            // were no-ops on a single-weight family, so they're dropped.
            largeTitle:  Font.custom("MajorMonoDisplay-Regular", size: 34, relativeTo: .largeTitle),
            title:       Font.custom("MajorMonoDisplay-Regular", size: 28, relativeTo: .title),
            title2:      Font.custom("MajorMonoDisplay-Regular", size: 22, relativeTo: .title2),
            title3:      Font.custom("MajorMonoDisplay-Regular", size: 20, relativeTo: .title3),
            heading:     Font.custom("MajorMonoDisplay-Regular", size: 17, relativeTo: .headline),
            subheadline: Font.custom("MajorMonoDisplay-Regular", size: 15, relativeTo: .subheadline),
            body:        Font.custom("MajorMonoDisplay-Regular", size: 17, relativeTo: .body),
            caption:     Font.custom("MajorMonoDisplay-Regular", size: 12, relativeTo: .caption),
            monospace:   .system(.body, design: .monospaced)
        )
    )

    /// DEF CON Red: black + crimson, system bold typography. Homage to
    /// DEF CON's classic palette.
    static let defconRed = AppTheme(
        id: "defconRed",
        displayName: "DEF CON Red",
        palette: ThemePalette(
            background: DualColor(
                light: Color(red: 250/255, green: 245/255, blue: 245/255), // #FAF5F5
                dark:  Color(red: 10/255,  green: 6/255,   blue: 6/255)    // #0A0606
            ),
            cardSurface: DualColor(
                light: Color(red: 247/255, green: 232/255, blue: 232/255), // #F7E8E8
                dark:  Color(red: 31/255,  green: 8/255,   blue: 8/255)    // #1F0808
            ),
            accent: DualColor(
                light: Color(red: 192/255, green: 0/255,   blue: 0/255),   // #C00000
                dark:  Color(red: 255/255, green: 45/255,  blue: 45/255)   // #FF2D2D
            ),
            success: DualColor(
                light: Color(red: 192/255, green: 0/255,   blue: 0/255),   // #C00000
                dark:  Color(red: 255/255, green: 45/255,  blue: 45/255)   // #FF2D2D
            ),
            danger: DualColor(
                light: Color(red: 178/255, green: 34/255,  blue: 34/255),  // #B22222
                dark:  Color(red: 255/255, green: 69/255,  blue: 0/255)    // #FF4500
            ),
            textPrimary: DualColor(
                light: .black,
                dark:  Color(red: 255/255, green: 230/255, blue: 230/255)
            ),
            textSecondary: DualColor(
                light: Color(red: 90/255,  green: 30/255,  blue: 30/255),
                dark:  Color(red: 200/255, green: 130/255, blue: 130/255)
            ),
            divider: DualColor(
                light: Color(.separator),
                dark:  Color(red: 60/255,  green: 20/255,  blue: 20/255)
            ),
            chipBackground: DualColor(
                light: Color(red: 240/255, green: 215/255, blue: 215/255),
                dark:  Color(red: 50/255,  green: 18/255,  blue: 18/255)
            )
        ),
        typography: ThemeTypography(
            largeTitle:  .system(.largeTitle).bold(),
            title:       .system(.title).bold(),
            title2:      .system(.title2).bold(),
            title3:      .system(.title3).bold(),
            heading:     .system(.headline),
            subheadline: .system(.subheadline),
            body:        .system(.body),
            caption:     .system(.caption),
            monospace:   .system(.body, design: .monospaced)
        )
    )

    /// Cyberpunk: electric cyan + warning yellow on deep navy. Retro-
    /// futurist neon. Rounded system typography throughout.
    static let cyberpunk = AppTheme(
        id: "cyberpunk",
        displayName: "Cyberpunk",
        palette: ThemePalette(
            background: DualColor(
                light: Color(red: 255/255, green: 252/255, blue: 235/255), // #FFFCEB
                dark:  Color(red: 5/255,   green: 8/255,   blue: 24/255)   // #050818
            ),
            cardSurface: DualColor(
                light: Color(red: 255/255, green: 245/255, blue: 200/255), // #FFF5C8
                dark:  Color(red: 14/255,  green: 20/255,  blue: 40/255)   // #0E1428
            ),
            accent: DualColor(
                light: Color(red: 0/255,   green: 139/255, blue: 139/255), // #008B8B
                dark:  Color(red: 0/255,   green: 255/255, blue: 255/255)  // #00FFFF
            ),
            success: DualColor(
                light: Color(red: 0/255,   green: 139/255, blue: 139/255), // #008B8B
                dark:  Color(red: 0/255,   green: 255/255, blue: 255/255)  // #00FFFF
            ),
            danger: DualColor(
                light: Color(red: 125/255, green: 92/255,  blue: 0/255),   // #7D5C00 — darker amber, ≥3:1 vs cardSurface
                dark:  Color(red: 255/255, green: 211/255, blue: 0/255)    // #FFD300
            ),
            textPrimary: DualColor(
                light: .black,
                dark:  Color(red: 220/255, green: 250/255, blue: 255/255)
            ),
            textSecondary: DualColor(
                light: Color(red: 70/255,  green: 70/255,  blue: 100/255),
                dark:  Color(red: 150/255, green: 200/255, blue: 220/255)
            ),
            divider: DualColor(
                light: Color(.separator),
                dark:  Color(red: 30/255,  green: 40/255,  blue: 80/255)
            ),
            chipBackground: DualColor(
                light: Color(red: 250/255, green: 240/255, blue: 180/255),
                dark:  Color(red: 20/255,  green: 30/255,  blue: 55/255)
            )
        ),
        typography: ThemeTypography(
            largeTitle:  .system(.largeTitle,  design: .rounded).bold(),
            title:       .system(.title,       design: .rounded).bold(),
            title2:      .system(.title2,      design: .rounded).bold(),
            title3:      .system(.title3,      design: .rounded).bold(),
            heading:     .system(.headline,    design: .rounded),
            subheadline: .system(.subheadline, design: .rounded),
            body:        .system(.body,        design: .rounded),
            caption:     .system(.caption,     design: .rounded),
            monospace:   .system(.body,        design: .monospaced)
        )
    )

    /// Vegas: gold + neon-pink on deep plum. Casino-marquee serif
    /// typography for that DEF CON Las Vegas home vibe.
    static let vegas = AppTheme(
        id: "vegas",
        displayName: "Vegas",
        palette: ThemePalette(
            background: DualColor(
                light: Color(red: 248/255, green: 239/255, blue: 255/255), // #F8EFFF
                dark:  Color(red: 24/255,  green: 11/255,  blue: 34/255)   // #180B22
            ),
            cardSurface: DualColor(
                light: Color(red: 235/255, green: 216/255, blue: 250/255), // #EBD8FA
                dark:  Color(red: 41/255,  green: 19/255,  blue: 64/255)   // #291340
            ),
            accent: DualColor(
                light: Color(red: 199/255, green: 21/255,  blue: 133/255), // #C71585
                dark:  Color(red: 255/255, green: 20/255,  blue: 147/255)  // #FF1493
            ),
            success: DualColor(
                light: Color(red: 199/255, green: 21/255,  blue: 133/255), // #C71585
                dark:  Color(red: 255/255, green: 20/255,  blue: 147/255)  // #FF1493
            ),
            danger: DualColor(
                light: Color(red: 178/255, green: 34/255,  blue: 34/255),  // #B22222
                dark:  Color(red: 255/255, green: 69/255,  blue: 0/255)    // #FF4500
            ),
            textPrimary: DualColor(
                light: .black,
                dark:  Color(red: 250/255, green: 240/255, blue: 220/255)
            ),
            textSecondary: DualColor(
                light: Color(red: 90/255,  green: 60/255,  blue: 110/255),
                dark:  Color(red: 215/255, green: 195/255, blue: 165/255)
            ),
            divider: DualColor(
                light: Color(.separator),
                dark:  Color(red: 100/255, green: 70/255,  blue: 130/255)
            ),
            chipBackground: DualColor(
                light: Color(red: 235/255, green: 220/255, blue: 245/255),
                dark:  Color(red: 60/255,  green: 35/255,  blue: 90/255)
            )
        ),
        typography: ThemeTypography(
            largeTitle:  .system(.largeTitle,  design: .serif).bold(),
            title:       .system(.title,       design: .serif).bold(),
            title2:      .system(.title2,      design: .serif).bold(),
            title3:      .system(.title3,      design: .serif).bold(),
            heading:     .system(.headline,    design: .serif),
            subheadline: .system(.subheadline, design: .serif),
            body:        .system(.body,        design: .serif),
            caption:     .system(.caption,     design: .serif),
            monospace:   .system(.body,        design: .monospaced)
        )
    )
}

/// Registry of all available themes. Adding a new theme is a one-line
/// append here once you've defined it as an `AppTheme` static.
enum ThemeRegistry {
    static let all: [AppTheme] = [.default, .hackerGreen, .synthwave, .defconRed, .cyberpunk, .vegas]
    static let fallback: AppTheme = .default
}

/// Spacing and sizing tokens for consistent layout across themes.
enum ThemeMetrics {
    /// Standard corner radius for card surfaces and semantic containers.
    /// Note: InfoView cards use 15 and small buttons use 5 — those are
    /// intentional design choices and left unchanged.
    static let cardRadius: CGFloat = 10
}

/// Observable holder for the active theme. Read by views via
/// `@Environment(ThemeManager.self)`.
///
/// Persistence is hand-rolled via UserDefaults rather than
/// `@AppStorage` because `@AppStorage` is a SwiftUI-View property
/// wrapper — embedding it in an `@Observable` class (even via
/// `@ObservationIgnored`) means mutations don't fire the observable
/// notifications views need to re-render. A plain stored String
/// property does fire those notifications; we sync to UserDefaults
/// explicitly in setTheme() so the choice survives launches.
@Observable
@MainActor
final class ThemeManager {
    private static let userDefaultsKey = "themeID"
    private static let lightModeKey = "lightMode"

    /// Backing storage. @Observable tracks reads + writes of this.
    private var storedID: String

    /// Light/dark selection, folded in from the legacy `Theme` class.
    /// Same hand-rolled persistence pattern as `storedID` (see the
    /// header comment): plain stored property for observation, synced
    /// to UserDefaults under the SAME "lightMode" key the old system
    /// used so existing user settings carry over.
    private var storedLightMode: Bool

    init() {
        self.storedID = UserDefaults.standard.string(forKey: ThemeManager.userDefaultsKey)
            ?? AppTheme.default.id
        self.storedLightMode = UserDefaults.standard.bool(forKey: ThemeManager.lightModeKey)
        applyNavBarAppearance()
    }

    /// App-wide color scheme. The app intentionally never returns nil
    /// (system-follow) — dark unless the user opted into light mode,
    /// matching the legacy Theme behavior.
    var preferredColorScheme: ColorScheme {
        storedLightMode ? .light : .dark
    }

    /// Flip light mode. The SettingsView Toggle binds its own
    /// @AppStorage("lightMode") for UI state and calls this in
    /// onChange so observation fires app-wide.
    func setLightMode(_ on: Bool) {
        storedLightMode = on
        UserDefaults.standard.set(on, forKey: ThemeManager.lightModeKey)
    }

    /// Colorful-mode card palette, folded in from the legacy
    /// `Theme.carousel()`. That version mutated a shared index per
    /// call, so card colors depended on render order; this is pure —
    /// pass the card's stable position and it always gets the same
    /// color.
    private static let carouselColors = ["#326295", "#71cc98", "#c16784", "#4b9560", "#c04c36"]
    func carouselColor(index: Int) -> Color {
        let colors = ThemeManager.carouselColors
        let hex = colors[((index % colors.count) + colors.count) % colors.count]
        return Color(UIColor(hex: hex) ?? .purple)
    }

    /// Carousel color for a String-keyed model (e.g. Organization,
    /// whose `id` is a Firestore `@DocumentID String?`). Derives a
    /// stable, launch-independent index from the key's scalars so the
    /// same org always gets the same tint.
    func carouselColor(forKey key: String) -> Color {
        carouselColor(index: key.unicodeScalars.reduce(0) { $0 + Int($1.value) })
    }

    /// The currently active theme. Falls back to the default if the
    /// stored id no longer matches a registered theme (e.g. user
    /// downgraded after removing a custom theme from the registry).
    var current: AppTheme {
        ThemeRegistry.all.first(where: { $0.id == storedID }) ?? ThemeRegistry.fallback
    }

    /// Switch themes. Updates the observable state (triggers
    /// re-renders) AND persists to UserDefaults so the choice
    /// survives launches.
    func setTheme(_ id: String) {
        guard ThemeRegistry.all.contains(where: { $0.id == id }) else { return }
        storedID = id
        UserDefaults.standard.set(id, forKey: ThemeManager.userDefaultsKey)
        applyNavBarAppearance()
    }

    /// Instance-level call site; just delegates to the static version
    /// using the currently-stored theme id. `@MainActor` because the
    /// static delegate touches UIKit appearance proxies.
    @MainActor
    private func applyNavBarAppearance() {
        ThemeManager.applyNavBarAppearance(for: storedID)
    }

    /// SwiftUI's `.navigationTitle` text is rendered by UINavigationBar
    /// under the hood, which doesn't pick up SwiftUI's `.font(_:)` env
    /// default. Push the active theme's heading + largeTitle face into
    /// `UINavigationBarAppearance` so nav-bar titles match the rest of
    /// the app.
    ///
    /// Static because it has to be callable from `hackertrackerApp.init()`
    /// BEFORE any `ThemeManager` instance is constructed — otherwise the
    /// app's initial UINavigationBars get instantiated against the
    /// default appearance and only refresh on push/pop. Reads the
    /// persisted theme id directly from UserDefaults.
    ///
    /// `@MainActor` because every UIKit appearance API touched here is
    /// main-actor-isolated under Swift 6. The two call sites (init,
    /// `hackertrackerApp.init()`) already run on the main actor.
    @MainActor
    static func applyNavBarAppearance(for themeID: String? = nil) {
        let resolvedID = themeID
            ?? UserDefaults.standard.string(forKey: ThemeManager.userDefaultsKey)
            ?? AppTheme.default.id
        let design: UIFontDescriptor.SystemDesign
        switch resolvedID {
        case "hackerGreen": design = .monospaced
        case "synthwave":   design = .rounded
        default:            design = .default
        }
        func font(for style: UIFont.TextStyle) -> UIFont {
            let baseDesc = UIFont.preferredFont(forTextStyle: style).fontDescriptor
            if design == .default {
                return UIFont.preferredFont(forTextStyle: style)
            }
            if let desc = baseDesc.withDesign(design) {
                return UIFont(descriptor: desc, size: 0)
            }
            return UIFont.preferredFont(forTextStyle: style)
        }
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.titleTextAttributes = [.font: font(for: .headline)]
        appearance.largeTitleTextAttributes = [.font: font(for: .largeTitle)]
        UINavigationBar.appearance().standardAppearance   = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance    = appearance
    }

    // MARK: - Convenience token accessors
    //
    // Returns auto-resolving Colors / Fonts so call sites stay terse.
    // Example:
    //   .background(themeManager.cardSurface)
    //   .font(themeManager.headingFont)

    var background: Color     { current.palette.background.auto }
    var cardSurface: Color    { current.palette.cardSurface.auto }
    var accent: Color         { current.palette.accent.auto }
    var success: Color        { current.palette.success.auto }
    var danger: Color         { current.palette.danger.auto }
    var textPrimary: Color    { current.palette.textPrimary.auto }
    var textSecondary: Color  { current.palette.textSecondary.auto }
    var divider: Color        { current.palette.divider.auto }
    var chipBackground: Color { current.palette.chipBackground.auto }

    /// SwiftUI `Font.Design` matching the active theme. Used by call
    /// sites that need the raw design value (e.g. MarkdownUI's
    /// `FontFamily(.system(_:))`, UIKit appearance proxies).
    var fontDesign: Font.Design {
        switch current.id {
        case "hackerGreen": return .monospaced
        case "synthwave":   return .rounded
        default:            return .default
        }
    }

    var largeTitleFont: Font  { current.typography.largeTitle }
    var titleFont: Font       { current.typography.title }
    var title2Font: Font      { current.typography.title2 }
    var title3Font: Font      { current.typography.title3 }
    var headingFont: Font     { current.typography.heading }
    var subheadlineFont: Font { current.typography.subheadline }
    var bodyFont: Font        { current.typography.body }
    var calloutFont: Font     { .system(.callout, design: fontDesign == .monospaced ? .monospaced : fontDesign == .rounded ? .rounded : .default) }
    var footnoteFont: Font    { current.typography.caption }
    var captionFont: Font     { current.typography.caption }
    var monospaceFont: Font   { current.typography.monospace }
}

import AVFoundation

/// Phase 3c: easter-egg audio player. Global mutable state pinned to MainActor
/// since only views (already MainActor) call playChik().
@MainActor private var player: AVAudioPlayer?

@MainActor
func playChik() {
    guard let path = Bundle.main.path(forResource: "rubber_\(Int.random(in: 1...5))", ofType:"mp3") else {
        return }
    let url = URL(fileURLWithPath: path)

    do {
        player = try AVAudioPlayer(contentsOf: url)
        player?.play()
        
    } catch let error {
        Log.ui.error("theme color decode failed: \(error.localizedDescription, privacy: .public)")
    }
}
