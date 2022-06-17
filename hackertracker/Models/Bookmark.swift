//
//  Bookmark.swift
//  hackertracker
//
//  Created by Seth W Law on 6/8/22.
//

import FirebaseFirestore
import FirebaseFirestoreSwift
import Foundation

struct Bookmark: Codable {
    @DocumentID var id: String?
    var value: Bool
}

class oBookmarks: ObservableObject {
    @Published var bookmarks: [Int] = []
}
