//
//  Product.swift
//  hackertracker
//
//  Created by Seth Law on 6/21/23.
//

import FirebaseFirestore
import FirebaseFirestoreSwift
import Foundation

struct Product: Codable, Identifiable {
    @DocumentID var docId: String?
    var id: Int
    var code: String
    var description: String
    var eligibilityRestrictionText: String?
    var isEligibilityRestricted: String
    var media: [Media]
    var priceMax: Int
    var priceMin: Int
    var productId: Int
    var sortOrder: Int
    var tags: [Int]
    var title: String
    var variants: [Variant]

    private enum CodingKeys: String, CodingKey {
        case id
        case code
        case description
        case eligibilityRestrictionText = "eligibility_restriction_text"
        case isEligibilityRestricted = "is_eligibility_restricted"
        case media
        case priceMax = "price_max"
        case priceMin = "price_min"
        case productId = "product_id"
        case sortOrder = "sort_order"
        case tags
        case title
        case variants
    }
}

struct Media: Codable {
    var assetId: Int
    var filetype: String
    var name: String
    var sortOrder: Int
    var url: String

    private enum CodingKeys: String, CodingKey {
        case assetId = "asset_id"
        case filetype
        case name
        case sortOrder = "sort_order"
        case url
    }
}

struct Variant: Codable, Identifiable {
    var id = UUID()
    var code: String
    var price: Int
    var sortOrder: Int
    var stockStatus: String
    var tags: [Int]
    var title: String
    var variantId: Int

    private enum CodingKeys: String, CodingKey {
        case code
        case price
        case sortOrder = "sort_order"
        case stockStatus = "stock_status"
        case tags
        case title
        case variantId = "variant_id"
    }
}
