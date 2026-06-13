//
//  MapView.swift
//  hackertracker
//
//  Created by Seth W Law on 6/6/22.
//

import FirebaseFirestore
import SwiftUI
import FirebaseAnalytics
import PDFKit

struct MapView: View {
    @EnvironmentObject var selected: SelectedConference
    @Environment(InfoViewModel.self) private var viewModel
    @EnvironmentObject var theme: Theme

    @State private var currentIndex: Int = 0
    @AppStorage("lastMapIndex") private var storedIndexBlob: String = ""

    /// Command sink for zoom + search. Bound to the focused map page so
    /// swipes hand off control automatically.
    @StateObject private var pdfController = MapController()

    /// Empty-state beezle: vertical offset animated while `bouncing`
    /// is true. `bounceTask` enforces a minimum 6s bounce window so a
    /// fast Firestore refresh doesn't snap the animation off the
    /// instant the data lands.
    @State private var emptyStateBouncing: Bool = false
    @State private var emptyStateBounceUp: Bool = false
    @State private var emptyStateBounceTask: Task<Void, Never>? = nil
    @Environment(\.colorScheme) private var mapViewColorScheme

    /// (#2) Share sheet for the active PDF file. Share always points at
    /// the PDF (better for printing / external apps) even when the screen
    /// is rendering the SVG version.
    @State private var shareURL: URL?

    /// Search UI state. Visible only when the focused page has an SVG
    /// loaded (`pdfController.canSearch`).
    @State private var isSearching: Bool = false
    @State private var searchText: String = ""
    @State private var searchMatches: Int = 0
    @FocusState private var searchFocused: Bool

    var body: some View {
        NavigationStack {
            content
                .overlay(alignment: .bottomLeading) { zoomFloatingControls }
                .padding(10)
                .background(Color(.systemBackground))
                .navigationTitle(currentMapTitle ?? "Maps")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbar { toolbarItems }
                .sheet(item: $shareURL) { url in
                    MapShareSheet(items: [url])
                }
        }
        .analyticsScreen(name: "MapView")
    }

    /// Floating zoom pill (In / Out / Reset) overlaid in the bottom-leading
    /// corner. .fixedSize() keeps it from stretching across the screen
    /// (Divider() inside a VStack defaults to filling the width).
    /// .buttonStyle(.plain) keeps SwiftUI from tinting the SF Symbols with
    /// the app accent color.
    @ViewBuilder private var zoomFloatingControls: some View {
        if currentMap != nil {
            HStack(spacing: 0) {
                zoomIcon(systemName: "plus.magnifyingglass", label: "Zoom in") {
                    pdfController.zoomIn()
                }
                Divider().frame(height: 22).opacity(0.5)
                zoomIcon(systemName: "minus.magnifyingglass", label: "Zoom out") {
                    pdfController.zoomOut()
                }
                Divider().frame(height: 22).opacity(0.5)
                zoomIcon(systemName: "arrow.up.left.and.down.right.magnifyingglass", label: "Reset zoom") {
                    pdfController.resetZoom()
                }
            }
            .fixedSize()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22))
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
            )
            .padding(.leading, 14)
            // Sit above the TabView's page indicator dots (~24pt high
            // including the background pill) plus a comfortable gap.
            .padding(.bottom, 52)
        }
    }

    private func zoomIcon(systemName: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.title3)
                .foregroundStyle(.primary)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    // MARK: - Layouts

    @ViewBuilder private var content: some View {
        VStack(spacing: 0) {
            emergencyBanner
            if let con = viewModel.conference {
                if let maps = sortedMaps, !maps.isEmpty {
                    if isSearching && currentMapHasSVG { searchBar }
                    // One-map-per-screen on every device. The previous iPad
                    // two-up landscape layout left too much whitespace
                    // between asymmetric floor plans; the single-pane swipe
                    // reads better at every size.
                    pagedLayout(maps: maps)
                } else {
                    emptyState(conference: con)
                }
            } else {
                _04View(message: "Loading...", show404: false)
                    .preferredColorScheme(theme.colorScheme)
            }
        }
    }

    private var sortedMaps: [Map]? {
        guard let maps = viewModel.conference?.maps else { return nil }
        return maps.sorted { $0.sortOrder < $1.sortOrder }
    }

    @ViewBuilder private var emergencyBanner: some View {
        if let emergId = viewModel.conference?.emergencyDocId,
           emergId > 0,
           let doc = viewModel.documentsById[emergId] {
            NavigationLink(destination: DocumentView(
                title_text: doc.title,
                body_text: doc.body,
                color: ThemeColors.red,
                systemImage: "exclamationmark.triangle.fill"
            )) {
                CardView(
                    systemImage: "exclamationmark.triangle.fill",
                    text: doc.title,
                    color: ThemeColors.red,
                    subtitle: "Tap for more details"
                )
                .frame(height: 40)
                .cornerRadius(0)
            }
        }
    }

    @ViewBuilder private func pagedLayout(maps: [Map]) -> some View {
        let _ = Self.logMapInventory(maps: maps, code: selected.code)
        TabView(selection: $currentIndex) {
            ForEach(Array(maps.enumerated()), id: \.element.id) { (index, map) in
                MapPage(
                    map: map,
                    conferenceCode: selected.code,
                    isFocused: index == currentIndex,
                    controller: pdfController
                )
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .onAppear { restoreIndex(maps: maps); applyPendingSearch() }
        .onChange(of: currentIndex) { _, new in
            persistIndex(new)
            prewarmAdjacent(maps: maps, around: new)
            applyPendingSearch()
        }
    }



    // MARK: - Toolbar

    @ToolbarContentBuilder private var toolbarItems: some ToolbarContent {
        // Share lives on the leading side of the nav bar (always points
        // at the PDF version, which is what users want to AirDrop / save).
        ToolbarItemGroup(placement: .navigationBarLeading) {
            if currentMap != nil {
                Button {
                    if let localURL = currentMapPDFLocalURL,
                       FileManager.default.fileExists(atPath: localURL.path) {
                        shareURL = localURL
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel("Share map (PDF)")
                .disabled(currentMapPDFLocalURL.flatMap { FileManager.default.fileExists(atPath: $0.path) } != true)
            }
        }
        // Search lives on the trailing side, but ONLY when the focused
        // page is rendering the SVG version (PDFs in this dataset rarely
        // carry indexable text, so a search button on a PDF would be
        // false advertising).
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            if currentMap != nil && currentMapHasSVG {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isSearching.toggle()
                    }
                    if isSearching {
                        searchFocused = true
                    } else {
                        searchText = ""
                        searchMatches = 0
                        pdfController.clearSearch()
                    }
                } label: {
                    Image(systemName: isSearching ? "xmark.circle" : "magnifyingglass")
                }
                .accessibilityLabel(isSearching ? "Close search" : "Search map")
            }
        }
    }

    // MARK: - Search bar (SVG-only)

    @ViewBuilder private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundColor(.secondary)
            TextField("Find on map (e.g. room number, village)", text: $searchText)
                .focused($searchFocused)
                .submitLabel(.search)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .onSubmit { Task { await runSearch() } }
                .onChange(of: searchText) { _, _ in
                    Task { await runSearch() }
                }
            if !searchText.isEmpty {
                Text(searchMatches == 0 ? "no match" : "\(searchMatches) hit\(searchMatches == 1 ? "" : "s")")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Button {
                    searchText = ""
                    searchMatches = 0
                    pdfController.clearSearch()
                } label: {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.thinMaterial)
        .cornerRadius(8)
        .padding(.horizontal, 6)
        .padding(.bottom, 4)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private func runSearch() async {
        searchMatches = await pdfController.search(searchText)
    }

    private func applyPendingSearch() {
        guard !searchText.isEmpty else { return }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 100_000_000)
            await runSearch()
        }
    }

    // MARK: - Index persistence

    private func decodeStoredIndex(code: String) -> Int? {
        for pair in storedIndexBlob.split(separator: ",") {
            let parts = pair.split(separator: "=", maxSplits: 1)
            if parts.count == 2, parts[0] == code, let i = Int(parts[1]) {
                return i
            }
        }
        return nil
    }

    private func encodedStoredIndex(code: String, index: Int) -> String {
        var pairs: [String] = []
        var found = false
        for pair in storedIndexBlob.split(separator: ",") {
            let parts = pair.split(separator: "=", maxSplits: 1)
            if parts.count == 2, parts[0] == code {
                pairs.append("\(code)=\(index)")
                found = true
            } else {
                pairs.append(String(pair))
            }
        }
        if !found {
            pairs.append("\(code)=\(index)")
        }
        return pairs.joined(separator: ",")
    }

    private func restoreIndex(maps: [Map]) {
        guard !maps.isEmpty else { return }
        if let stored = decodeStoredIndex(code: selected.code) {
            currentIndex = min(max(0, stored), maps.count - 1)
        } else {
            currentIndex = 0
        }
        prewarmAdjacent(maps: maps, around: currentIndex)
    }

    private func persistIndex(_ index: Int) {
        storedIndexBlob = encodedStoredIndex(code: selected.code, index: index)
    }

    // MARK: - Prewarm

    private func prewarmAdjacent(maps: [Map], around index: Int) {
        for offset in [-1, 1] {
            let i = index + offset
            guard maps.indices.contains(i) else { continue }
            // PDF prewarm only — SVG load through WKWebView is fast enough
            // and parsing an SVG twice isn't catastrophic.
            if let url = URL(string: maps[i].url) {
                let path = "\(selected.code)/\(url.lastPathComponent)"
                let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let local = docDir.appendingPathComponent(path)
                PDFDocumentCache.prewarm(local)
            }
        }
    }

    // MARK: - Current map helpers

    private var currentMap: Map? {
        guard let maps = sortedMaps, maps.indices.contains(currentIndex) else { return nil }
        return maps[currentIndex]
    }

    private var currentMapTitle: String? {
        currentMap?.description ?? currentMap.map { _ in "Maps" }
    }

    /// True when the focused map has an `svg_url` and the local SVG
    /// file exists on disk. Drives the search button visibility so
    /// the button shows up even before the WKWebView has finished
    /// registering itself with the controller (which is racy on a
    /// fresh swipe).
    private var currentMapHasSVG: Bool {
        guard let m = currentMap,
              let raw = m.resolvedSvgPath,
              let remote = URL(string: raw) else { return false }
        let path = "\(selected.code)/\(remote.lastPathComponent)"
        let local = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(path)
        return FileManager.default.fileExists(atPath: local.path)
    }

    /// Always the PDF URL (share button target).
    private var currentMapPDFLocalURL: URL? {
        guard let m = currentMap, let url = URL(string: m.url) else { return nil }
        let path = "\(selected.code)/\(url.lastPathComponent)"
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(path)
    }

    // MARK: - Empty state

    @ViewBuilder private func emptyState(conference: Conference) -> some View {
        VStack(spacing: 16) {
            ContentUnavailableView(
                "No Maps Yet",
                systemImage: "map",
                description: Text("Maps for \(conference.name) haven't been published. Pull to refresh, or check back closer to the event.")
            )
            // 40pt beezle, light-mode safe via .beezleAdaptiveColor.
            // Bounce is driven via withAnimation(... .repeatForever ...)
            // on tap rather than a permanent .animation modifier — the
            // modifier form picks up the bool flip back to false too and
            // keeps animating, so the bob never actually stops. The
            // explicit start/stop transactions in startEmptyStateBounce
            // settle cleanly after the 3s window.
            Image("beezle")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .beezleAdaptiveColor(mapViewColorScheme)
                .offset(y: emptyStateBounceUp ? -10 : 0)
                .accessibilityHidden(true)
            Button {
                viewModel.fetchData(code: conference.code)
                startEmptyStateBounce()
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
        }
        .frame(maxHeight: .infinity)
    }

    /// Kick off (or restart) a 3-second spring bounce on the empty-state
    /// beezle. The explicit withAnimation(...repeatForever...) starts the
    /// oscillation in one transaction, and a follow-up withAnimation(...)
    /// without repeatForever after 3s cleanly settles the offset back to
    /// 0. Repeated taps cancel the previous timer and start a fresh 3s
    /// window so the bounce never gets clipped mid-cycle.
    private func startEmptyStateBounce() {
        emptyStateBounceTask?.cancel()
        withAnimation(.spring(response: 0.32, dampingFraction: 0.45).repeatForever(autoreverses: true)) {
            emptyStateBounceUp = true
        }
        emptyStateBounceTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                emptyStateBounceUp = false
            }
        }
    }
}

/// One map page in the swipe TabView (or one cell in the iPad two-up
/// layout).
///
/// Display rules:
///   - If the conference published an `svg_url` AND the local file exists,
///     render `SVGMapView` (searchable, vector, pinch-zoom).
///   - Otherwise render the PDF via `PDFView`.
/// The PDF download still happens regardless so the share button always
/// has something to hand to UIActivityViewController.
private struct MapPage: View {
    let map: Map
    let conferenceCode: String
    let isFocused: Bool
    let controller: MapController?

    @State private var pdfExists: Bool = false
    @State private var svgExists: Bool = false

    private var pdfLocalURL: URL? {
        guard let url = URL(string: map.url) else { return nil }
        return localURL(for: url)
    }

    private var svgLocalURL: URL? {
        guard let raw = map.resolvedSvgPath, let url = URL(string: raw) else { return nil }
        return localURL(for: url)
    }

    private func localURL(for remote: URL) -> URL {
        let path = "\(conferenceCode)/\(remote.lastPathComponent)"
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(path)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if let svg = svgLocalURL, svgExists {
                SVGMapView(url: svg, controller: controller, isFocused: isFocused)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let pdf = pdfLocalURL, pdfExists {
                PDFView(url: pdf, controller: controller, isFocused: isFocused)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if pdfLocalURL != nil || svgLocalURL != nil {
                downloadingPlaceholder
            } else {
                ContentUnavailableView("Invalid Map", systemImage: "questionmark.square")
            }
            if let desc = map.description {
                Text(desc)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.thinMaterial)
                    .cornerRadius(6)
                    .padding(8)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(map.description ?? "Conference map")
        .accessibilityHint("Pinch or use the zoom buttons; swipe to switch maps")
        .task(id: pdfLocalURL?.path) { refreshExists() }
        .task(id: svgLocalURL?.path) { refreshExists() }
        .onAppear {
            Log.ui.debug("MapView loading pdf=\(pdfLocalURL?.lastPathComponent ?? "?", privacy: .public) svg=\(svgLocalURL?.lastPathComponent ?? "—", privacy: .public)")
        }
    }

    @Environment(\.colorScheme) private var beezleColorScheme
    @State private var beezleBob: Bool = false

    /// Friendlier placeholder while the PDF/SVG is still downloading.
    /// Borrows the beezle ghost from 404View and gives it a gentle
    /// bob + tilt so users see the app is alive instead of a static
    /// spinner. The ProgressView under it carries the actual semantic
    /// "still working" signal for VoiceOver.
    @ViewBuilder private var downloadingPlaceholder: some View {
        VStack(spacing: 16) {
            Image("beezle")
                .resizable()
                .scaledToFit()
                .frame(width: 140, height: 140)
                .beezleAdaptiveColor(beezleColorScheme)
                .offset(y: beezleBob ? -8 : 8)
                .rotationEffect(.degrees(beezleBob ? 4 : -4))
                .animation(
                    .easeInOut(duration: 1.4).repeatForever(autoreverses: true),
                    value: beezleBob
                )
                .accessibilityHidden(true)
            VStack(spacing: 6) {
                ProgressView()
                Text("Map downloading…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { beezleBob = true }
        .task(id: pdfLocalURL?.path) { await pollForFiles() }
    }

    private func refreshExists() {
        pdfExists = pdfLocalURL.map { FileManager.default.fileExists(atPath: $0.path) } ?? false
        svgExists = svgLocalURL.map { FileManager.default.fileExists(atPath: $0.path) } ?? false
    }

    @MainActor private func pollForFiles() async {
        for _ in 0..<60 {
            try? await Task.sleep(nanoseconds: 500_000_000)
            refreshExists()
            if pdfExists || svgExists { return }
        }
    }
}

/// UIActivityViewController wrapper.
struct MapShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

extension MapView {
    @MainActor private static var loggedCodes: Set<String> = []
    static func logMapInventory(maps: [Map], code: String) {
        guard !loggedCodes.contains(code) else { return }
        loggedCodes.insert(code)
        let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        for m in maps {
            let pdfFile = (URL(string: m.url)?.lastPathComponent).map { "\(code)/\($0)" } ?? "?"
            let pdfExists = FileManager.default.fileExists(atPath: docDir.appendingPathComponent(pdfFile).path)
            let svgFile: String
            let svgExists: Bool
            if let raw = m.resolvedSvgPath, let u = URL(string: raw) {
                svgFile = "\(code)/\(u.lastPathComponent)"
                svgExists = FileManager.default.fileExists(atPath: docDir.appendingPathComponent(svgFile).path)
            } else {
                svgFile = "<none>"
                svgExists = false
            }
            Log.ui.info("MapInventory \(code, privacy: .public) [\(m.id, privacy: .public)] \(m.description ?? "?", privacy: .public) pdf=\(pdfFile, privacy: .public)(\(pdfExists, privacy: .public)) svg=\(svgFile, privacy: .public)(\(svgExists, privacy: .public)) svgFilename=\(m.svgFilename ?? "—", privacy: .public) svgUrl=\(m.svgUrl ?? "—", privacy: .public)")
        }
    }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        Text("Map View")
    }
}

struct SpinnerView: View {
    var body: some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: ThemeColors.blue))
            .scaleEffect(2.0, anchor: .center)
    }
}

// Beezle is a white-on-transparent silhouette. It looks fine on dark
// backgrounds but vanishes on light ones. .colorInvert() flips white
// pixels to black while preserving the asset's internal value
// differences (the eye shading was being collapsed when we ran it
// through .renderingMode(.template) + .foregroundStyle(.primary)).
//
// Has to live as a View extension rather than a ViewModifier struct
// because this module's own `Content` model shadows ViewModifier's
// associated type `Content`, which makes the modifier protocol fail
// to resolve inside `body(content:)`.
extension View {
    @ViewBuilder
    func beezleAdaptiveColor(_ scheme: ColorScheme) -> some View {
        if scheme == .light {
            self.colorInvert()
        } else {
            self
        }
    }
}
