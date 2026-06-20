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
