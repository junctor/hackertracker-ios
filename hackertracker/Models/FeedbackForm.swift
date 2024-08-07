//
//  FeedbackForm.swift
//  hackertracker
//
//  Created by Seth Law on 7/25/24.
//

import FirebaseFirestore
import Foundation

struct FeedbackForm: Codable, Identifiable {
    var id: Int
    var name: String
    var submissionUrl: String
    var items: [FeedbackItem]
    
    private enum CodingKeys: String, CodingKey {
        case id
        case name = "name_text"
        case submissionUrl = "submission_url"
        case items
    }
}

struct FeedbackItem: Codable, Identifiable {
    var id: Int
    var captionText: String
    var options: [FeedbackOption]
    var selectMin: Int
    var selectMax: Int
    var selectOrientation: String
    var sortOrder: Int
    var textMaxLength: Int?
    var type: String
    
    private enum CodingKeys: String, CodingKey {
        case id
        case captionText = "caption_text"
        case options
        case selectMin = "select_minimum"
        case selectMax = "select_maximum"
        case selectOrientation = "select_orientation"
        case sortOrder = "sort_order"
        case textMaxLength = "text_max_length"
        case type
    }
}

struct FeedbackOption: Codable, Identifiable {
    var id: Int
    var captionText: String
    var sortOrder: Int
    
    private enum CodingKeys: String, CodingKey {
        case id
        case captionText = "caption_text"
        case sortOrder = "sort_order"
    }
}

struct Feedback: Codable {
    var id: Int
}
