//
//  ScrollTitleHandoff.swift
//  hackertracker
//
//  Tiny helper for the iOS Mail-style "in-content title merges into the nav
//  bar on scroll" effect used by ContentDetailView and SpeakerDetailView.
//
//  Apply `.trackTitleScrollOffset()` to the large in-content title Text,
//  then read `TitleScrollOffsetKey` via `.onPreferenceChange` to drive a
//  toolbar ToolbarItem(placement: .principal) that fades in once the title
//  has scrolled past the navigation bar.
//

import SwiftUI

struct TitleScrollOffsetKey: PreferenceKey {
    // Swift 6 strict: `static let` satisfies the `static var defaultValue { get }`
    // PreferenceKey requirement and keeps the value immutable (no shared mutable
    // state warning).
    static let defaultValue: CGFloat = .greatestFiniteMagnitude
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

extension View {
    /// Publishes this view's bottom-edge Y position in global coordinates via
    /// `TitleScrollOffsetKey`. Use on the large in-content title Text.
    func trackTitleScrollOffset() -> some View {
        background(
            GeometryReader { proxy in
                Color.clear
                    .preference(key: TitleScrollOffsetKey.self,
                                value: proxy.frame(in: .global).maxY)
            }
        )
    }
}
