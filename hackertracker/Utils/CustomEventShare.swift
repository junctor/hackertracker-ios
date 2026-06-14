//
//  CustomEventShare.swift
//  hackertracker
//
//  Encode + decode CustomEvent payloads for the QR-code share flow.
//
//  Share URL shape:
//      hackertracker://import/customEvent?t=<title>&b=<unix>&e=<unix>
//                       [&d=<desc>][&l=<loc>][&c=<hex>][&k=A,B][&x=0|1]
//
//  Keys are kept short so the resulting QR code stays a low-density
//  version that's reliably scannable by the iOS camera even when the
//  description carries a paragraph or two.
//
//  Notes are intentionally NOT shared — they're a private journal
//  field on the source device, not part of the public event identity.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Plain-old-value drafting struct used to pre-fill CustomEventFormView
/// after a scanned URL is decoded. Mirrors the CustomEvent attributes
/// the form lets the user edit.
struct CustomEventDraft {
    var title: String
    var eventDescription: String?
    var begin: Date
    var end: Date
    var location: String?
    var conferenceCodes: [String]
    var colorHex: String?
    var notificationsEnabled: Bool
}

enum CustomEventShare {
    /// URL host used for non-conference deep-link routes.
    static let importHost = "import"
    /// URL path that triggers the customEvent import flow.
    static let importPath = "/customEvent"
    /// Full prefix consumers can pattern-match against.
    static let importURLPrefix = "hackertracker://import/customEvent?"

    // MARK: - Encode

    /// Build a deep-link URL representing the supplied event. Returns
    /// nil only when the source is missing required title / time fields.
    static func url(for event: CustomEvent) -> URL? {
        guard let title = event.title,
              !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let begin = event.beginTimestamp,
              let end = event.endTimestamp else { return nil }

        var comps = URLComponents()
        comps.scheme = "hackertracker"
        comps.host = importHost
        comps.path = importPath

        var items: [URLQueryItem] = [
            URLQueryItem(name: "t", value: title),
            URLQueryItem(name: "b", value: String(Int(begin.timeIntervalSince1970))),
            URLQueryItem(name: "e", value: String(Int(end.timeIntervalSince1970))),
        ]
        if let d = event.eventDescription, !d.isEmpty {
            items.append(URLQueryItem(name: "d", value: d))
        }
        if let l = event.location, !l.isEmpty {
            items.append(URLQueryItem(name: "l", value: l))
        }
        if let c = event.colorHex, !c.isEmpty {
            // Drop the leading '#' so the QR doesn't waste a byte on it.
            let trimmed = c.hasPrefix("#") ? String(c.dropFirst()) : c
            items.append(URLQueryItem(name: "c", value: trimmed))
        }
        let codes = (event.conferenceCodes as? [String]) ?? []
        if !codes.isEmpty {
            items.append(URLQueryItem(name: "k", value: codes.joined(separator: ",")))
        }
        // Always include x so the receiver knows the sender's intent.
        items.append(URLQueryItem(name: "x", value: event.notificationsEnabled ? "1" : "0"))

        comps.queryItems = items
        return comps.url
    }

    // MARK: - Decode

    /// Parse a deep-link URL produced by `url(for:)` into a CustomEventDraft.
    /// Returns nil when required fields are missing or malformed.
    static func draft(from url: URL) -> CustomEventDraft? {
        guard url.scheme == "hackertracker",
              url.host == importHost,
              url.path == importPath,
              let comps = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        let items = Dictionary(uniqueKeysWithValues: (comps.queryItems ?? []).map { ($0.name, $0.value ?? "") })

        guard let title = items["t"], !title.isEmpty,
              let bRaw = items["b"], let bSec = Int(bRaw),
              let eRaw = items["e"], let eSec = Int(eRaw) else { return nil }

        let begin = Date(timeIntervalSince1970: TimeInterval(bSec))
        let end = Date(timeIntervalSince1970: TimeInterval(eSec))

        var colorHex: String? = nil
        if let raw = items["c"], !raw.isEmpty {
            // We strip the '#' on encode; put it back so consumers see the
            // same hex shape that lives on CustomEvent.colorHex on the
            // sender's device.
            colorHex = raw.hasPrefix("#") ? raw : "#" + raw
        }

        let codes: [String]
        if let raw = items["k"], !raw.isEmpty {
            codes = raw.split(separator: ",").map(String.init)
        } else {
            codes = []
        }

        let notify = items["x"] == "1"

        return CustomEventDraft(
            title: title,
            eventDescription: items["d"].flatMap { $0.isEmpty ? nil : $0 },
            begin: begin,
            end: max(end, begin), // never let end precede begin after decode
            location: items["l"].flatMap { $0.isEmpty ? nil : $0 },
            conferenceCodes: codes,
            colorHex: colorHex,
            notificationsEnabled: notify
        )
    }
}

// .sheet(item:) requires Identifiable. We don't have a stable id on
// the draft itself, so synthesize one from the title + begin epoch —
// good enough since drafts are short-lived UI state, not persisted.
extension CustomEventDraft: Identifiable {
    var id: String { "\(title)|\(Int(begin.timeIntervalSince1970))" }
}
