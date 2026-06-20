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
    @MainActor
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

    /// Detail-screen rounded cards on iPad read as "floating" tiles below
    /// a flat nav bar, which makes the right detail pane look misaligned
    /// from the left list. On iPad this returns the given radius as 0
    /// (flat); on iPhone it passes through unchanged.
    @MainActor
    func iPadFlatCorners(_ radius: CGFloat = 15) -> some View {
        self.cornerRadius(UIDevice.current.userInterfaceIdiom == .pad ? 0 : radius)
    }

    /// Replace the system base background with the active theme's
    /// background color. Hides the default ScrollView background so
    /// the themed color shows through; the result extends under the
    /// nav bar (whose .ultraThinMaterial picks up the tint) and the
    /// safe-area edges.
    ///
    /// Apply this at the root of each tab's body, e.g.:
    /// `NavigationStack { ... }.themedBackground(themeManager)`
    func themedBackground(_ themeManager: ThemeManager) -> some View {
        self
            .scrollContentBackground(.hidden)
            .background(themeManager.background, ignoresSafeAreaEdges: .all)
    }
}

enum IPadAdaptive {
    /// Single source of truth for the iPad split-view sidebar width.
    /// Used by Schedule (EventsView), Speakers, All Content, Merch,
    /// and Communities (OrgsView). Bumped from the per-view 380/420
    /// hodgepodge to a single 500pt so the left list panel uses
    /// roughly 42% of an 11" iPad's landscape width, matching the
    /// visual density of the Communities grid and keeping the right
    /// detail pane from looking sparse.
    static let sidebarWidth: CGFloat = 500

    /// `true` when running on iPad. Use sparingly -- prefer the
    /// `iPadReadableContent` modifier when possible.
    ///
    /// `@MainActor` because `UIDevice.current` is main-actor isolated
    /// under Swift 6 strict concurrency. All current call sites are
    /// SwiftUI view bodies, which are already on the main actor.
    @MainActor
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

// MARK: - iPad split-view selection plumbing

/// Environment value carrying a `Binding<Int?>` for content selection in
/// an iPad NavigationSplitView. EventData / ContentData rows read this --
/// when non-nil, a tap sets the binding's wrappedValue instead of pushing
/// a NavigationLink to ContentDetailView. iPhone leaves the env value
/// `nil` so rows keep their existing NavigationStack push behavior.
private struct IPadContentSelectionKey: EnvironmentKey {
    static let defaultValue: Binding<Int?>? = nil
}

extension EnvironmentValues {
    var iPadContentSelection: Binding<Int?>? {
        get { self[IPadContentSelectionKey.self] }
        set { self[IPadContentSelectionKey.self] = newValue }
    }
}

/// Environment value carrying a `Binding<Int?>` for speaker selection on
/// iPad. SpeakersView's row Buttons set this; SpeakersView's detail
/// column renders SpeakerDetailView(id: $0).
private struct IPadSpeakerSelectionKey: EnvironmentKey {
    static let defaultValue: Binding<Int?>? = nil
}

extension EnvironmentValues {
    var iPadSpeakerSelection: Binding<Int?>? {
        get { self[IPadSpeakerSelectionKey.self] }
        set { self[IPadSpeakerSelectionKey.self] = newValue }
    }
}

/// Environment value carrying a `Binding<String?>` for org selection on iPad.
/// Org IDs are Firestore @DocumentID strings, not Ints.
private struct IPadOrgSelectionKey: EnvironmentKey {
    static let defaultValue: Binding<String?>? = nil
}

extension EnvironmentValues {
    var iPadOrgSelection: Binding<String?>? {
        get { self[IPadOrgSelectionKey.self] }
        set { self[IPadOrgSelectionKey.self] = newValue }
    }
}

/// Environment value carrying a `Binding<Int?>` for merch product selection
/// on iPad.
private struct IPadProductSelectionKey: EnvironmentKey {
    static let defaultValue: Binding<Int?>? = nil
}

extension EnvironmentValues {
    var iPadProductSelection: Binding<Int?>? {
        get { self[IPadProductSelectionKey.self] }
        set { self[IPadProductSelectionKey.self] = newValue }
    }
}

/// Environment value carrying a `Binding<UUID?>` for custom-event
/// selection on iPad. EventsView's row branch sets this when the
/// tapped event is locally-stored (event.customEventID is non-nil)
/// so the detail lands in the right pane instead of pushing onto
/// the sidebar's NavigationStack (which would replace the list).
private struct IPadCustomEventSelectionKey: EnvironmentKey {
    static let defaultValue: Binding<UUID?>? = nil
}

extension EnvironmentValues {
    var iPadCustomEventSelection: Binding<UUID?>? {
        get { self[IPadCustomEventSelectionKey.self] }
        set { self[IPadCustomEventSelectionKey.self] = newValue }
    }
}

// MARK: - Notes badge plumbing
//
// EventCellView and ContentCellView each need to know "does this row
// have a saved private Note?" Per-cell @FetchRequest worked in some
// contexts but not others (LazyVStack reentrancy / SwiftUI macro
// timing). The robust fix is the same parent-publishes-into-env
// pattern we use for iPad selection bindings: the parent view holds
// a single FetchedResults<Note> + computes a Set of targetIDs, then
// publishes the set via .environment(\.noteEventIDs, ...) /
// .environment(\.noteContentIDs, ...). Cells read the value directly.
//
// Defaults to empty so cells used in screens that don't publish (e.g.
// GlobalSearchView) silently skip the pencil badge.
private struct NoteEventIDsKey: EnvironmentKey {
    static let defaultValue: Set<Int32> = []
}
private struct NoteContentIDsKey: EnvironmentKey {
    static let defaultValue: Set<Int32> = []
}

extension EnvironmentValues {
    var noteEventIDs: Set<Int32> {
        get { self[NoteEventIDsKey.self] }
        set { self[NoteEventIDsKey.self] = newValue }
    }
    var noteContentIDs: Set<Int32> {
        get { self[NoteContentIDsKey.self] }
        set { self[NoteContentIDsKey.self] = newValue }
    }
}
