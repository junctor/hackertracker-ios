//
//  PDFView.swift
//  hackertracker
//
//  Created by Seth Law on 6/21/23.
//

import PDFKit
import SwiftUI

/// Command sink the MapView attaches to so toolbar/floating-pill
/// commands hit the right backing view (PDF or SVG WebView). Held
/// weakly so swapping the focused page doesn't keep the previous view
/// alive past its dismantle.
///
/// The controller is intentionally simple: it dispatches to whichever
/// target is non-nil. MapPage sets the appropriate ref when it becomes
/// the focused page (and clears its peers via reassignment).
@MainActor
final class MapController: ObservableObject {
    weak var pdfTarget: PDFKit.PDFView?
    weak var svgTarget: SVGMapWebContainer?

    var canSearch: Bool { svgTarget != nil }

    func zoomIn() {
        if let svg = svgTarget { svg.zoomIn(); return }
        guard let v = pdfTarget else { return }
        v.scaleFactor = min(v.scaleFactor * 1.25, v.maxScaleFactor)
    }

    func zoomOut() {
        if let svg = svgTarget { svg.zoomOut(); return }
        guard let v = pdfTarget else { return }
        v.scaleFactor = max(v.scaleFactor / 1.25, v.minScaleFactor)
    }

    func resetZoom() {
        if let svg = svgTarget { svg.resetZoom(); return }
        guard let v = pdfTarget else { return }
        v.scaleFactor = v.scaleFactorForSizeToFit
    }

    /// SVG-only. Returns the match count for the focused page.
    /// Returns 0 when there's no SVG target (PDF doesn't expose search).
    func search(_ query: String) async -> Int {
        guard let svg = svgTarget else { return 0 }
        let res = await svg.search(query)
        return res.matches
    }

    func clearSearch() {
        Task { _ = await svgTarget?.search("") }
    }
}

// Back-compat alias so we don't have to rename every PDFController
// reference in views in this pass.
typealias PDFController = MapController

/// SwiftUI wrapper around `PDFKit.PDFView`.
///
/// Three behaviors the original wrapper got wrong, all visible on the Maps
/// tab when the user swipes between pages:
///
/// 1. **Black flash on swipe.** `PDFKit.PDFView`'s default `backgroundColor`
///    is a dark system gray, which reads as solid black on first paint and
///    while a freshly-instantiated page parses its document. Force a clear
///    background so the SwiftUI background shows through during the
///    transition.
/// 2. **Synchronous document parse on main thread.** `PDFDocument(url:)`
///    reads + parses the entire PDF on the calling thread; on a multi-MB
///    map this can stall the swipe gesture for hundreds of milliseconds.
///    Load it off main and assign on main when ready.
/// 3. **Redundant reloads on every SwiftUI update.** `updateUIView` was
///    reassigning `.document` on every recompute, even when the URL had
///    not changed. That re-parses the PDF and resets the visible page.
///    Skip the assignment when the URL is unchanged.
///
/// A tiny in-process cache keyed by absolute path stops repeated swipes
/// across the same pages from re-parsing each time.
struct PDFView: UIViewRepresentable {
    let url: URL
    /// When non-nil and `isFocused` is true, the view registers itself with
    /// this controller so toolbar zoom/search commands hit it.
    var controller: PDFController? = nil
    /// In a TabView .page list every map page is materialized but only the
    /// visible one should respond to toolbar commands. Set true for the
    /// page whose index matches `currentIndex` so the controller binds
    /// to it (and not to its siblings).
    var isFocused: Bool = false

    func makeUIView(context: Context) -> PDFKit.PDFView {
        let view = PDFKit.PDFView()
        view.autoScales = true
        view.backgroundColor = .clear
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.maxScaleFactor = 5.0
        view.minScaleFactor = 0.1
        configure(view, with: url)
        if isFocused {
            controller?.pdfTarget = view
            controller?.svgTarget = nil
        }
        return view
    }

    func updateUIView(_ pdfView: PDFKit.PDFView, context: Context) {
        // Only reload when the URL actually changed. Without this guard,
        // every SwiftUI recompute of the parent (e.g. a swipe redraw)
        // would re-parse the document and reset the scroll position.
        if pdfView.document?.documentURL != url {
            configure(pdfView, with: url)
        }
        if isFocused {
            controller?.pdfTarget = pdfView
            controller?.svgTarget = nil
        }
    }

    private func configure(_ view: PDFKit.PDFView, with url: URL) {
        if let cached = PDFDocumentCache.shared[url] {
            view.document = cached
            scheduleFitToView(view)
            return
        }
        // Off-main load so the swipe gesture stays responsive on large maps.
        Task.detached(priority: .userInitiated) {
            let doc = PDFDocument(url: url)
            await MainActor.run {
                if let doc {
                    PDFDocumentCache.shared[url] = doc
                    if view.document?.documentURL != url {
                        view.document = doc
                    } else if view.document == nil {
                        view.document = doc
                    }
                    scheduleFitToView(view)
                }
            }
        }
    }

    /// Force a fit-to-view scale on the next runloop tick so the
    /// initial paint of each map shows the whole page. `autoScales`
    /// alone is unreliable when the document is assigned before the
    /// view has laid out (it returns 0 from `scaleFactorForSizeToFit`).
    /// Hopping to the next runloop guarantees layout has run. Done
    /// twice (immediate + small delay) so cached documents that come
    /// in pre-laid-out also get the fit.
    @MainActor private func scheduleFitToView(_ view: PDFKit.PDFView) {
        DispatchQueue.main.async {
            let fit = view.scaleFactorForSizeToFit
            if fit > 0 { view.scaleFactor = fit }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            let fit = view.scaleFactorForSizeToFit
            if fit > 0 { view.scaleFactor = fit }
        }
    }
}

/// Process-lifetime LRU cache for parsed `PDFDocument`s, keyed by absolute path.
/// Maps don't change at runtime, so once parsed they're reused to avoid re-parsing.
/// An LRU eviction policy prevents unbounded memory growth when the user visits
/// multiple conferences with many maps (each conference's maps and prewarmed neighbors
/// are retained; old conferences' maps are evicted as new ones are accessed).
///
/// Capacity is 12 documents: typically a conference has 1-4 maps, and prewarming
/// loads the current page plus adjacent pages in the TabView (3 simultaneous). With
/// 12 slots, a user can visit 3+ conferences and maintain responsive map access
/// for the current + 2 neighbor pages without unbounded growth.
@MainActor
final class PDFDocumentCache {
    static let shared = PDFDocumentCache()

    /// Maximum number of PDFDocuments to retain. When the cache fills beyond
    /// this, the least-recently-used document is evicted on the next insertion.
    private static let capacityLimit = 12

    /// Ordered list of (URL, document) pairs; index 0 is LRU, end is MRU.
    /// Using a small array keeps append/remove O(n) but n is small (≤12).
    private var lruOrder: [(URL, PDFDocument)] = []

    subscript(url: URL) -> PDFDocument? {
        get {
            // Find and move to MRU (end of array)
            if let index = lruOrder.firstIndex(where: { $0.0 == url }) {
                let item = lruOrder.remove(at: index)
                lruOrder.append(item)
                return item.1
            }
            return nil
        }
        set {
            if let newValue {
                // Remove existing entry with this URL if present
                lruOrder.removeAll { $0.0 == url }

                // Evict LRU (first element) if at capacity
                if lruOrder.count >= Self.capacityLimit {
                    lruOrder.removeFirst()
                }

                // Insert at MRU (end)
                lruOrder.append((url, newValue))
            } else {
                // Explicit nil assignment removes the entry
                lruOrder.removeAll { $0.0 == url }
            }
        }
    }

    /// Synchronously parse and cache `url` if not already cached. Safe to
    /// call from a background `Task.detached`; the actor hop on the
    /// subscript writes guards the cache.
    static func prewarm(_ url: URL) {
        Task.detached(priority: .utility) {
            let already = await MainActor.run { PDFDocumentCache.shared[url] != nil }
            if already { return }
            // FileManager and PDFDocument both read off-actor safely; only
            // the cache write hops back to main.
            guard FileManager.default.fileExists(atPath: url.path) else { return }
            let doc = PDFDocument(url: url)
            await MainActor.run {
                if let doc { PDFDocumentCache.shared[url] = doc }
            }
        }
    }
}
