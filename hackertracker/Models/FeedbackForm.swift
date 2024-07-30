//
//  FeedbackForm.swift
//  hackertracker
//
//  Created by Seth Law on 7/25/24.
//

import FirebaseFirestore
import FirebaseFirestoreSwift
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

struct FeedbackOptionSelectOne {
    var item_id: Int
    var options: [Int]
}

struct FeedbackOptionText {
    var item_id: Int
    var options: String
}

struct FeedbackAnswers {
    var client: String
    var conference_id: Int
    var content_id: Int
    var device_id: String
    var feedback_form_id: Int
    var items: [AnyObject]
    var timestamp: String
}
