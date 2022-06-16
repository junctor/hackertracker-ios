//
//  ViewModifiers.swift
//  hackertracker
//
//  Created by caleb on 6/16/22.
//

import SwiftUI

struct RectangleBackground: ViewModifier {
    func body(content: Content) -> some View {
        content.padding(10).multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Rectangle().fill(Color(UIColor(hex: "#2d2d2D") ?? UIColor.gray))).cornerRadius(5)
    }
}

extension View {
    func rectangleBackground() -> some View {
        modifier(RectangleBackground())
    }
}
