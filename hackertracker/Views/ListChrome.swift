//
//  ListChrome.swift
//  hackertracker
//
//  Shared chrome for the "search + jump" pattern repeated across the
//  top-level list screens (Conferences, Merch, Orgs/Vendors, News, FAQs,
//  and the Speakers / All Content search field). Extracted to remove
//  near-identical copies that had begun to drift in small ways
//  (padding, wording, accessibility labels). Screens with a
//  structurally different jump menu (EventsView's day + Top/Now/Next/
//  Bottom via ScrollCommandBus; Speakers' / All Content's alphabet
//  jump-to-group; MapView's live in-document search with match count)
//  keep their own copies rather than being force-fit into this shape.
//

import SwiftUI

/// Inline search field shown below the nav bar, toggled by
/// `SearchToggleButton`. Reproduces the shared layout: magnifying-glass
/// icon, text field, conditional clear button, thin-material background,
/// and a move+opacity transition.
struct InlineSearchBar: View {
    let placeholder: String
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    let visible: Bool

    var body: some View {
        if visible {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                TextField(placeholder, text: $text)
                    .focused(isFocused)
                    .submitLabel(.search)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                if !text.isEmpty {
                    Button {
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                    }
                    .accessibilityLabel("Clear search text")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.thinMaterial)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}

/// Toolbar button that toggles `InlineSearchBar`'s visibility, handing
/// focus to the field on open and clearing the search text on close.
struct SearchToggleButton: View {
    @Binding var isSearching: Bool
    @Binding var searchText: String
    var isFocused: FocusState<Bool>.Binding
    /// e.g. "Search merch" / "Search conferences" — used for the
    /// accessibility label while the field is closed.
    let searchLabel: String

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isSearching.toggle()
            }
            if isSearching {
                isFocused.wrappedValue = true
            } else {
                searchText = ""
            }
        } label: {
            Image(systemName: isSearching ? "xmark.circle" : "magnifyingglass")
        }
        .accessibilityLabel(isSearching ? "Close search" : searchLabel)
    }
}

/// Floating bottom-trailing "Top / Bottom" jump menu shared by the list
/// screens that only need to jump to the ends of a single scroll region
/// (as opposed to EventsView's per-day menu or the alphabet jump-to-group
/// menus). Sets `target` to "__top" / "__bottom", which callers observe
/// via `.onChange` against matching `Color.clear.frame(height: 1).id(...)`
/// anchors.
struct JumpMenu: View {
    @Binding var target: String?

    var body: some View {
        Menu {
            Button {
                target = "__top"
            } label: { Label("Top", systemImage: "arrow.up") }
            Button {
                target = "__bottom"
            } label: { Label("Bottom", systemImage: "arrow.down") }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
        .menuOrder(.fixed)
    }
}

/// Applies the standard floating-circle chrome (48x48, title2 font,
/// regularMaterial circle, "Jump" accessibility label) around a
/// `JumpMenu`. Matches the styling every copy site applied by hand.
struct JumpMenuOverlay: View {
    @Binding var target: String?
    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        JumpMenu(target: $target)
            .font(themeManager.title2Font)
            .foregroundStyle(.primary)
            .frame(width: 48, height: 48)
            .background(.regularMaterial, in: Circle())
            .accessibilityLabel("Jump")
    }
}
