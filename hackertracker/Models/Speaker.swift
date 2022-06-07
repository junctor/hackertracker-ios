//
//  Speaker.swift
//  hackertracker
//
//  Created by Seth W Law on 6/6/22.
//

import Foundation
import FirebaseFirestoreSwift

struct Speaker: Codable {
    var id: Int
    var conferenceName: String
    var description: String
    var link: String
    var name: String
    var title: String
    var twitter: String
    var events: [Event]
}
