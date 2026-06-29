//
//  Conference.swift
//  hackertracker
//
//  Created by Seth W Law on 6/6/22.
//

import FirebaseFirestore
import Foundation
import SwiftUI

struct Conference: Codable, Identifiable, Equatable {
    static func == (lhs: Conference, rhs: Conference) -> Bool {
        lhs.code == rhs.code
    }
    
    @DocumentID var docId: String?
    var id: Int
    var name: String
    var description: String
    var code: String
    var endDate: String
    var startDate: String
    var timezone: String?
    var coc: String?
    var kickoffTimestamp: Date
    var startTimestamp: Date
    var endTimestamp: Date
    var maps: [Map]?
    var documents: [Document]?
    var hidden: Bool
    var enableMerch: Bool
    var enableMerchCart: Bool
    var homeMenuId: Int
    var tagline: String?
    var merchHelpDocId: Int?
    var merchMandatoryAck: String?
    var merchTaxStatement: String?
    var emergencyDocId: Int?
    /// Optional per-conference branding assets. Each entry carries
    /// `dark` and/or `light` variants — the picker resolves which to
    /// show based on the active color scheme.
    var media: [ConferenceMediaEntry]?

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case code
        case endDate = "end_date"
        case startDate = "start_date"
        case timezone
        case coc = "codeofconduct"
        case kickoffTimestamp = "kickoff_timestamp"
        case startTimestamp = "start_timestamp"
        case endTimestamp = "end_timestamp"
        case maps
        case documents
        case hidden
        case enableMerch = "enable_merch"
        case enableMerchCart = "enable_merch_cart"
        case homeMenuId = "home_menu_id"
        case tagline = "tagline_text"
        case merchHelpDocId = "merch_help_doc_id"
        case merchMandatoryAck = "merch_mandatory_acknowledgement"
        case merchTaxStatement = "merch_tax_statement"
        case emergencyDocId = "emergency_document_id"
        case media
    }

    /// First square-logo URL string available for the requested
    /// appearance, falling back to the opposite variant if the
    /// requested one isn't published. Returns nil when no media is
    /// configured at all.
    func squareLogo(for colorScheme: ColorScheme) -> String? {
        guard let media, !media.isEmpty else { return nil }
        let preferred: (ConferenceMediaEntry) -> String? = {
            colorScheme == .dark
                ? { $0.dark?.squareLogo }
                : { $0.light?.squareLogo }
        }()
        let fallback: (ConferenceMediaEntry) -> String? = {
            colorScheme == .dark
                ? { $0.light?.squareLogo }
                : { $0.dark?.squareLogo }
        }()
        if let hit = media.compactMap(preferred).first(where: { !$0.isEmpty }) {
            return hit
        }
        return media.compactMap(fallback).first(where: { !$0.isEmpty })
    }
}

/// One entry in `Conference.media`. Either side may be missing — a
/// conference may publish only a dark logo, only a light one, or
/// both. Field names match the Firestore document
/// (banner_background, banner_logo, square_logo).
struct ConferenceMediaEntry: Codable, Equatable {
    var dark: ConferenceMediaImages?
    var light: ConferenceMediaImages?
}

struct ConferenceMediaImages: Codable, Equatable {
    var bannerBackground: String?
    var bannerLogo: String?
    var squareLogo: String?

    private enum CodingKeys: String, CodingKey {
        case bannerBackground = "banner_background"
        case bannerLogo = "banner_logo"
        case squareLogo = "square_logo"
    }
}
