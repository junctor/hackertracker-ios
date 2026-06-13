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

    /// Current map's position in the sorted list. Bound to the TabView
    /// selection so the toolbar (title, share, zoom, search) always
    /// reflects the visible page. Persisted per conference so reopening
    /// the tab returns to the user's last spot.
    @State private var currentIndex: Int = 0
    /// Per-conference last-viewed index (#4). Conferences ship different
    /// map sets, so we key by conference code rather than a single global.
    @AppStorage("lastMapIndex") private var storedIndexBlob: String = ""

    /// (#1, #7) Command sink for zoom/search. Bound to the focused map
    /// page so swipes hand off control automatically.
    @StateObject private var pdfController = PDFController()

    /// (#2) Share sheet for the active PDF file.
    @State private var shareURL: URL?

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

    /// Floating zoom control in the bottom-leading corner. The three
    /// icons (In / Out / Reset) share a single rounded-rect Material
    /// pill so the affordance reads as one cohesive control instead
    /// of three disconnected circles. `.buttonStyle(.plain)` keeps
    /// SwiftUI from tinting the icons with the app accent color (blue).
    @ViewBuilder private var zoomFloatingControls: some View {
        if currentMap != nil {
            VStack(spacing: 0) {
                zoomIcon(systemName: "plus.magnifyingglass", label: "Zoom in") {
                    pdfController.zoomIn()
                }
                Divider().opacity(0.5)
                zoomIcon(systemName: "minus.magnifyingglass", label: "Zoom out") {
                    pdfController.zoomOut()
                }
                Divider().opacity(0.5)
                zoomIcon(systemName: "arrow.up.left.and.down.right.magnifyingglass", label: "Reset zoom") {
                    pdfController.resetZoom()
                }
            }
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22))
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
            )
            .padding(.leading, 14)
            .padding(.bottom, 20)
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
                    GeometryReader { proxy in
                        if useTwoUpLayout(geometry: proxy) {
                            twoUpLayout(maps: maps)
                        } else {
                            pagedLayout(maps: maps)
                        }
                    }
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

    /// Default paged layout (iPhone, iPad portrait). One full-width PDF
    /// per swipe page.
    @ViewBuilder private func pagedLayout(maps: [Map]) -> some View {
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
        .onAppear { restoreIndex(maps: maps) }
        .onChange(of: currentIndex) { _, new in
            persistIndex(new)
            prewarmAdjacent(maps: maps, around: new)
        }
    }

    /// (#6) iPad landscape: render the current map and its successor side
    /// by side. Stepper buttons advance the pair so the layout reads as
    /// a two-page spread.
    @ViewBuilder private func twoUpLayout(maps: [Map]) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                MapPage(
                    map: maps[currentIndex],
                    conferenceCode: selected.code,
                    isFocused: true,
                    controller: pdfController
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                if currentIndex + 1 < maps.count {
                    Divider()
                    MapPage(
                        map: maps[currentIndex + 1],
                        conferenceCode: selected.code,
                        isFocused: false,
                        controller: nil
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            HStack {
                Button {
                    if currentIndex >= 2 { currentIndex -= 2 } else { currentIndex = 0 }
                } label: {
                    Image(systemName: "chevron.left.circle.fill").font(.title)
                }
                .disabled(currentIndex == 0)
                Spacer()
                Text("\(currentIndex + 1)\(maps.count > currentIndex + 1 ? "–\(currentIndex + 2)" : "") of \(maps.count)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    if currentIndex + 2 < maps.count { currentIndex += 2 }
                } label: {
                    Image(systemName: "chevron.right.circle.fill").font(.title)
                }
                .disabled(currentIndex + 2 >= maps.count)
            }
            .padding(.horizontal, 12)
        }
        .onAppear { restoreIndex(maps: maps) }
        .onChange(of: currentIndex) { _, new in
            persistIndex(new)
            prewarmAdjacent(maps: maps, around: new)
        }
    }

    private func useTwoUpLayout(geometry proxy: GeometryProxy) -> Bool {
        guard IPadAdaptive.isIPad else { return false }
        return proxy.size.width > proxy.size.height
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder private var toolbarItems: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            if currentMap != nil {
                Button {
                    if let localURL = currentMapLocalURL,
                       FileManager.default.fileExists(atPath: localURL.path) {
                        shareURL = localURL
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel("Share map")
                .disabled(currentMapLocalURL.flatMap { FileManager.default.fileExists(atPath: $0.path) } != true)
            }
        }
    }

    // MARK: - Index persistence (#4)

    /// `storedIndexBlob` packs `code1=3,code2=1` pairs so each conference
    /// remembers its own last-viewed map without colliding.
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

    // MARK: - Adjacent prewarm (#5)

    private func prewarmAdjacent(maps: [Map], around index: Int) {
        for offset in [-1, 1] {
            let i = index + offset
            guard maps.indices.contains(i) else { continue }
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

    private var currentMapLocalURL: URL? {
        guard let m = currentMap, let url = URL(string: m.url) else { return nil }
        let path = "\(selected.code)/\(url.lastPathComponent)"
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(path)
    }

    // MARK: - Empty state (#9)

    @ViewBuilder private func emptyState(conference: Conference) -> some View {
        VStack(spacing: 12) {
            ContentUnavailableView(
                "No Maps Yet",
                systemImage: "map",
                description: Text("Maps for \(conference.name) haven't been published. Pull to refresh, or check back closer to the event.")
            )
            Button {
                viewModel.fetchData(code: conference.code)
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
        }
        .frame(maxHeight: .infinity)
    }
}

/// One map page in the swipe TabView (or one cell in the iPad two-up
/// layout). Owns the file-existence check (#8) and the per-page
/// accessibility label (#10).
private struct MapPage: View {
    let map: Map
    let conferenceCode: String
    let isFocused: Bool
    let controller: PDFController?

    @State private var fileExists: Bool = false

    private var localURL: URL? {
        guard let url = URL(string: map.url) else { return nil }
        let path = "\(conferenceCode)/\(url.lastPathComponent)"
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(path)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if let url = localURL, fileExists {
                PDFView(url: url, controller: controller, isFocused: isFocused)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if localURL != nil {
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
        .task(id: localURL?.path) { refreshExists() }
        .onAppear {
            Log.ui.debug("MapView loading \(localURL?.lastPathComponent ?? "?", privacy: .public)")
        }
    }

    @ViewBuilder private var downloadingPlaceholder: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Map downloading…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task(id: localURL?.path) { await pollForFile() }
    }

    private func refreshExists() {
        fileExists = localURL.map { FileManager.default.fileExists(atPath: $0.path) } ?? false
    }

    /// (#8) Map files are downloaded by InfoViewModel on conference load.
    /// If the user reaches MapView before that finishes, poll every
    /// half-second for up to 30s so the placeholder swaps in once the
    /// file arrives without forcing a manual refresh.
    @MainActor private func pollForFile() async {
        for _ in 0..<60 {
            try? await Task.sleep(nanoseconds: 500_000_000)
            refreshExists()
            if fileExists { return }
        }
    }
}

/// (#2) Plain UIActivityViewController wrapper so SwiftUI can present it
/// via `.sheet(item:)`. Items are URLs to local PDF files in the
/// per-conference cache directory.
struct MapShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

/// Make URL `Identifiable` so `.sheet(item:)` can present it directly.
extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
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
