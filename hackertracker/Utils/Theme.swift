//
//  Theme.swift
//  hackertracker
//
//  Created by caleb on 6/17/22.
//

import SwiftUI

class Theme {
    let colors = ["#c16784", "#326295", "#71cc98", "#4b9560", "#c04c36"]
    let font = ThemeFont()
    var index = 0

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
