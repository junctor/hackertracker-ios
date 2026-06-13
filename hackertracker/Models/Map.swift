//
//  Map.swift
//  hackertracker
//
//  Created by Seth W Law on 6/6/22.
//

import FirebaseFirestore
import Foundation

struct Map: Codable, Identifiable {
    @DocumentID var docID: String?
    var id: Int
    var url: String
    var description: String?
    var file: String?
    /// When the server provides a searchable, vector version of the
    /// map alongside the PDF, MapView prefers it for display + search
    /// while keeping the PDF for share/export.
    ///
    /// Field naming varies across conferences: some publish
    /// `svg_filename`, some `svg_url`. We accept either; lookup order
    /// is svg_filename → svg_url → PDF fallback.
    var svgFilename: String?
    var svgUrl: String?
    var sortOrder: Int

    /// Resolved SVG asset URL. Server-side convention is URL-only:
    /// prefer `svg_url`, then `svg_filename` if it looks like a URL.
    /// Returns nil when neither yields a fetchable URL.
    var resolvedSvgPath: String? {
        if let u = svgUrl, !u.trimmingCharacters(in: .whitespaces).isEmpty {
            return u
        }
        if let f = svgFilename,
           !f.trimmingCharacters(in: .whitespaces).isEmpty,
           f.lowercased().hasPrefix("http") {
            return f
        }
        return nil
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case url
        case description = "name_text"
        case file = "filename"
        case svgFilename = "svg_filename"
        case svgUrl = "svg_url"
        case sortOrder = "sort_order"
    }
}
