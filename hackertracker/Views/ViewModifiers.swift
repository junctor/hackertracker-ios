//
//  ViewModifiers.swift
//  hackertracker
//
//  Created by caleb on 6/16/22.
//

import SwiftUI

struct RectangleBackground: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content.padding(10).multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Rectangle().fill(colorScheme == .dark ? hexSwiftUIColor(hex: "#2d2d2D") : hexSwiftUIColor(hex: "#eeeeee")).cornerRadius(5))
    }
}

extension View {
    func rectangleBackground() -> some View {
        modifier(RectangleBackground())
    }
}
