//
//  iPadAdaptive.swift
//  hackertracker
//
//  iPad-only adaptive layout helpers. Detection is by
//  UIDevice.userInterfaceIdiom == .pad so iPhones (including Pro Max in
//  landscape, which reports a `.regular` horizontal size class) are
//  intentionally NOT included -- iPhone UI is unchanged by these modifiers.
//
//  Apple HIG references:
//   - Readable line lengths: aim for roughly 50-75 characters per line.
//   - Centered content columns with generous side margins on iPad.
//   - Adaptive grids that grow column count with available width.
//
//  Implementation note: cannot use a ViewModifier(content:) struct here
//  because our hackertracker module has its own `Content` model, which
//  shadows the ViewModifier protocol's `Content` associated type and
//  fails name resolution inside `body(content:)`. Use direct View
//  extensions instead.
//

import SwiftUI

extension View {
    /// On iPad: constrains the content to `maxWidth` (default 740pt) and
    /// centers it horizontally inside the available space. On iPhone: no-op.
    /// Place this *inside* a ScrollView around the row content so the
    /// scroll surface stays full-width while the visible content sits in a
    /// readable centered column.
    @ViewBuilder
    func iPadReadableContent(maxWidth: CGFloat = 740) -> some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            self
                .frame(maxWidth: maxWidth)
                .frame(maxWidth: .infinity)
        } else {
            self
        }
    }
}

enum IPadAdaptive {
    /// `true` when running on iPad. Use sparingly -- prefer the
    /// `iPadReadableContent` modifier when possible.
    static var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    /// Grid columns sized by minimum width. Gives 2 columns on every
    /// iPhone width (170 * 2 + spacing < 390), grows on iPad portrait
    /// (~4-5 columns at 820pt) and iPad landscape (~6 columns at 1180pt).
    static func adaptiveGridColumns(minimum: CGFloat = 170,
                                    alignment: Alignment = .top) -> [GridItem] {
        [GridItem(.adaptive(minimum: minimum), alignment: alignment)]
    }
}
