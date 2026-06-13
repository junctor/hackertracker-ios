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

    /// Resolved SVG asset path. Prefers `svg_filename` (the field
    /// most current conferences populate) and falls back to
    /// `svg_url`. Returns nil when neither is set or both are empty.
    var resolvedSvgPath: String? {
        if let f = svgFilename, !f.trimmingCharacters(in: .whitespaces).isEmpty {
            return f
        }
        if let u = svgUrl, !u.trimmingCharacters(in: .whitespaces).isEmpty {
            return u
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
