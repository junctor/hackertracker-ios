//
//  Theme.swift
//  hackertracker
//
//  Created by caleb on 6/17/22.
//

import SwiftUI

class Theme: ObservableObject {
    @AppStorage("lightMode") var lightMode: Bool = false
    @Published var colorScheme: ColorScheme = .dark

    let colors = ["#326295", "#71cc98", "#c16784", "#4b9560", "#c04c36"]
    let font = ThemeFont()
    var index = 0
    
    init() {
        if lightMode {
            self.colorScheme = .light
        } else {
            self.colorScheme = .dark
        }
    }

    func carousel() -> Color {
        if index >= colors.count {
            index = 0
        }

        let color = colors[index]
        index += 1

        return Color(UIColor(hex: color) ?? .purple)
    }
}

struct ThemeFont {
    let bold = "Futura Bold"
    let regular = "Futura Medium"
    let italic = "Futura Medium Italic"
}

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
    let cardSurface: DualColor   // standout-button and detail-card fill
    let accent: DualColor         // primary tinted action color
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
    let heading: Font
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
            cardSurface: .cardSurface,
            accent: DualColor(
                light: ThemeColors.blue,
                dark:  ThemeColors.blue
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
            largeTitle: .largeTitle,
            heading:    .headline,
            body:       .body,
            caption:    .caption,
            monospace:  .system(.body, design: .monospaced)
        )
    )
}

/// Registry of all available themes. Adding a new theme is a one-line
/// append here once you've defined it in `AppTheme+<Name>.swift` (or
/// inline below for small ones).
enum ThemeRegistry {
    static let all: [AppTheme] = [.default]
    static let fallback: AppTheme = .default
}

/// Observable holder for the active theme. Read by views via
/// `@Environment(ThemeManager.self)` once PR 2 migrates call sites.
/// Persistence is via `@AppStorage("themeID")` — survives launches,
/// scoped to the install.
@Observable
final class ThemeManager {
    @ObservationIgnored
    @AppStorage("themeID") private var storedID: String = AppTheme.default.id

    /// The currently active theme. Falls back to the default if the
    /// stored id no longer matches a registered theme (e.g. user
    /// downgraded after removing a custom theme from the registry).
    var current: AppTheme {
        ThemeRegistry.all.first(where: { $0.id == storedID }) ?? ThemeRegistry.fallback
    }

    /// Switch themes. Updates @AppStorage so the choice survives
    /// launches; @Observable triggers re-renders in any view reading
    /// `current`.
    func setTheme(_ id: String) {
        guard ThemeRegistry.all.contains(where: { $0.id == id }) else { return }
        storedID = id
    }

    // MARK: - Convenience token accessors
    //
    // Returns auto-resolving Colors / Fonts so call sites stay terse.
    // Example:
    //   .background(themeManager.cardSurface)
    //   .font(themeManager.headingFont)

    var cardSurface: Color    { current.palette.cardSurface.auto }
    var accent: Color         { current.palette.accent.auto }
    var danger: Color         { current.palette.danger.auto }
    var textPrimary: Color    { current.palette.textPrimary.auto }
    var textSecondary: Color  { current.palette.textSecondary.auto }
    var divider: Color        { current.palette.divider.auto }
    var chipBackground: Color { current.palette.chipBackground.auto }

    var largeTitleFont: Font { current.typography.largeTitle }
    var headingFont: Font    { current.typography.heading }
    var bodyFont: Font       { current.typography.body }
    var captionFont: Font    { current.typography.caption }
    var monospaceFont: Font  { current.typography.monospace }
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
