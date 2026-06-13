//
//  SVGMapView.swift
//  hackertracker
//
//  Searchable, zoomable SVG map renderer.
//
//  Why a WKWebView instead of a native SVG parser:
//   - Native SwiftUI / UIKit can't display SVGs without a third-party
//     library. SVGKit is unmaintained; SwiftDraw is heavy and renders to
//     a static UIImage (kills search + smooth zoom).
//   - WebKit renders SVG to vector and gives us pinch-zoom for free via
//     the embedded UIScrollView.
//   - The SVG's own DOM is queryable from JavaScript, so the search
//     feature operates directly on the document's <text>/<tspan>/<title>
//     elements -- no separate index needed, and highlights are applied
//     by toggling CSS classes (lossless, instant).
//

import SwiftUI
import WebKit

/// Search outcome surfaced back to MapView so it can render a "no match"
/// indicator or a result counter.
struct SVGSearchResult {
    let query: String
    let matches: Int
}

/// Backing object for `SVGMapView`. Mirrors the role `PDFKit.PDFView`
/// plays for the PDF path: holds a weak ref so MapController can route
/// zoom + search commands to the focused page. Lifecycle is managed by
/// the SwiftUI `UIViewRepresentable` wrapper below.
@MainActor
final class SVGMapWebContainer: UIView {
    let webView: WKWebView

    override init(frame: CGRect) {
        let cfg = WKWebViewConfiguration()
        cfg.allowsInlineMediaPlayback = true
        cfg.suppressesIncrementalRendering = false
        webView = WKWebView(frame: .zero, configuration: cfg)
        super.init(frame: frame)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.backgroundColor = .clear
        webView.isOpaque = false
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.minimumZoomScale = 0.25
        webView.scrollView.maximumZoomScale = 8.0
        webView.scrollView.bouncesZoom = true
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.showsHorizontalScrollIndicator = false
        addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: topAnchor),
            webView.leadingAnchor.constraint(equalTo: leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) not used") }

    // MARK: - Zoom

    func zoomIn() {
        let s = webView.scrollView
        s.setZoomScale(min(s.zoomScale * 1.25, s.maximumZoomScale), animated: true)
    }
    func zoomOut() {
        let s = webView.scrollView
        s.setZoomScale(max(s.zoomScale / 1.25, s.minimumZoomScale), animated: true)
    }
    func resetZoom() {
        webView.scrollView.setZoomScale(1.0, animated: true)
        webView.scrollView.setContentOffset(.zero, animated: true)
    }

    // MARK: - Search

    /// Highlight every `<text>` / `<tspan>` / `<title>` whose textContent
    /// contains `query` (case-insensitive), scroll the first match into
    /// view, and report the number of hits. An empty query clears the
    /// existing highlight.
    func search(_ query: String) async -> SVGSearchResult {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        let escaped = trimmed
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
            .replacingOccurrences(of: "\n", with: " ")
        let js = "window.htSearch && htSearch('\(escaped)')"
        return await withCheckedContinuation { cont in
            webView.evaluateJavaScript(js) { value, _ in
                let count = (value as? Int) ?? (value as? NSNumber)?.intValue ?? 0
                cont.resume(returning: SVGSearchResult(query: trimmed, matches: count))
            }
        }
    }

    // MARK: - Load

    /// Build an HTML wrapper around the on-disk SVG so we can attach
    /// search highlight CSS + a tiny JS search function. The SVG is
    /// inlined (read from disk) rather than referenced via <img>/<object>
    /// because cross-document JS access into an <object>'s contentDocument
    /// is fiddly and varies across iOS versions.
    func load(svgURL: URL) {
        guard let svg = try? String(contentsOf: svgURL, encoding: .utf8) else {
            // Fallback: ask the webview to render the file directly. Search
            // won't work in that mode but the user at least sees the map.
            webView.loadFileURL(svgURL, allowingReadAccessTo: svgURL.deletingLastPathComponent())
            return
        }
        let html = SVGMapWebContainer.htmlTemplate(inlining: svg)
        webView.loadHTMLString(html, baseURL: svgURL.deletingLastPathComponent())
    }

    private static func htmlTemplate(inlining svg: String) -> String {
        // Notes:
        //  - <meta viewport> lets pinch-zoom work cleanly through WebKit's
        //    built-in scroll view + double-tap-to-zoom gestures.
        //  - .ht-hit applies a bright fill + thicker stroke override so
        //    matched text stands out on any map background. !important
        //    beats inline styles set by the design tools that author the
        //    SVGs (Affinity / Illustrator both emit inline styles).
        //  - htSearch() is the only entry point Swift calls. Keep it
        //    side-effect-free other than DOM class toggles + scroll.
        """
        <!doctype html>
        <html>
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1, user-scalable=yes, minimum-scale=0.25, maximum-scale=8">
        <style>
          html, body { margin: 0; padding: 0; background: transparent; height: 100%; }
          body { display: flex; align-items: center; justify-content: center; }
          svg { max-width: 100%; max-height: 100%; height: auto; width: auto; }
          .ht-hit { fill: #ffd60a !important; stroke: #b07a00 !important; stroke-width: 2px !important; }
          .ht-hit-first { outline: 3px solid #ffd60a; }
        </style>
        </head>
        <body>
        \(svg)
        <script>
        (function() {
          window.htSearch = function(query) {
            // Clear any previous highlight first.
            document.querySelectorAll('.ht-hit').forEach(function(e) {
              e.classList.remove('ht-hit');
              e.classList.remove('ht-hit-first');
            });
            if (!query) return 0;
            var q = query.toLowerCase();
            // <title> elements describe accessibility labels for the
            // surrounding shape; including them lets users search for
            // rooms whose label sits in a <title> rather than visible text.
            var els = document.querySelectorAll('text, tspan, title');
            var hits = [];
            els.forEach(function(el) {
              var t = (el.textContent || '').toLowerCase();
              if (t.indexOf(q) !== -1) {
                el.classList.add('ht-hit');
                hits.push(el);
              }
            });
            if (hits.length > 0) {
              hits[0].classList.add('ht-hit-first');
              var rect = hits[0].getBoundingClientRect();
              window.scrollTo({
                left: rect.left + window.scrollX - (window.innerWidth / 2) + (rect.width / 2),
                top:  rect.top  + window.scrollY - (window.innerHeight / 2) + (rect.height / 2),
                behavior: 'smooth'
              });
            }
            return hits.length;
          };
        })();
        </script>
        </body>
        </html>
        """
    }
}

/// SwiftUI wrapper that exposes the container above. Mirrors PDFView's
/// shape so MapView can swap between PDF and SVG behind a single
/// `isFocused` / `controller` plumbing.
struct SVGMapView: UIViewRepresentable {
    let url: URL
    var controller: MapController? = nil
    var isFocused: Bool = false

    func makeUIView(context: Context) -> SVGMapWebContainer {
        let v = SVGMapWebContainer(frame: .zero)
        v.load(svgURL: url)
        if isFocused {
            controller?.svgTarget = v
            controller?.pdfTarget = nil
        }
        return v
    }

    func updateUIView(_ v: SVGMapWebContainer, context: Context) {
        if isFocused {
            controller?.svgTarget = v
            controller?.pdfTarget = nil
        }
    }
}
