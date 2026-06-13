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
    var svgUrl: String?
    var sortOrder: Int

    private enum CodingKeys: String, CodingKey {
        case id
        case url
        case description = "name_text"
        case file = "filename"
        case svgUrl = "svg_url"
        case sortOrder = "sort_order"
    }
}
