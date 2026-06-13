//
//  PDFView.swift
//  hackertracker
//
//  Created by Seth Law on 6/21/23.
//

import PDFKit
import SwiftUI

/// Command sink the MapView attaches to so its toolbar zoom/search buttons
/// can drive the focused page's underlying `PDFKit.PDFView`. Held weakly
/// so swapping the focused page (a swipe) doesn't keep the previous view
/// alive past its dismantle.
@MainActor
final class PDFController: ObservableObject {
    weak var pdfView: PDFKit.PDFView?

    func zoomIn() {
        guard let v = pdfView else { return }
        v.scaleFactor = min(v.scaleFactor * 1.25, v.maxScaleFactor)
    }

    func zoomOut() {
        guard let v = pdfView else { return }
        v.scaleFactor = max(v.scaleFactor / 1.25, v.minScaleFactor)
    }

    func resetZoom() {
        guard let v = pdfView else { return }
        v.scaleFactor = v.scaleFactorForSizeToFit
    }

    /// Find the first occurrence of `query` in the focused PDF and scroll
    /// to it. Returns `true` when a match was found. Empty queries clear
    /// the highlight and return `false`.
    @discardableResult
    func find(_ query: String) -> Bool {
        guard let v = pdfView else { return false }
        guard let doc = v.document, !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            v.clearSelection()
            return false
        }
        let matches = doc.findString(query, withOptions: [.caseInsensitive])
        guard let first = matches.first else {
            v.clearSelection()
            return false
        }
        v.setCurrentSelection(first, animate: true)
        v.go(to: first)
        return true
    }

    func clearSearch() {
        pdfView?.clearSelection()
    }
}

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
        view.minScaleFactor = 0.5
        configure(view, with: url)
        if isFocused {
            controller?.pdfView = view
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
            controller?.pdfView = pdfView
        }
    }

    private func configure(_ view: PDFKit.PDFView, with url: URL) {
        if let cached = PDFDocumentCache.shared[url] {
            view.document = cached
            return
        }
        // Off-main load so the swipe gesture stays responsive on large maps.
        Task.detached(priority: .userInitiated) {
            let doc = PDFDocument(url: url)
            await MainActor.run {
                if let doc {
                    PDFDocumentCache.shared[url] = doc
                    // Only assign if this view still wants the same URL.
                    if view.document?.documentURL != url {
                        view.document = doc
                    } else if view.document == nil {
                        view.document = doc
                    }
                }
            }
        }
    }
}

/// Process-lifetime cache for parsed `PDFDocument`s, keyed by absolute path.
/// Maps don't change at runtime, so once parsed they stay in memory until
/// the app is killed. Conferences ship with only a handful of maps, so the
/// memory cost is negligible compared to re-parsing on every swipe.
@MainActor
final class PDFDocumentCache {
    static let shared = PDFDocumentCache()
    private var storage: [URL: PDFDocument] = [:]

    subscript(url: URL) -> PDFDocument? {
        get { storage[url] }
        set { storage[url] = newValue }
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
