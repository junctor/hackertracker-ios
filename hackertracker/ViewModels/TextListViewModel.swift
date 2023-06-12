//
//  TextListViewModel.swift
//  hackertracker
//
//  Created by Seth W Law on 6/10/23.
//

import FirebaseFirestore
import Foundation
import SwiftUI

class TextListViewModel: ObservableObject {
    @Published var faqs = [FAQ]()
    @Published var news = [Article]()

    private var db = Firestore.firestore()

    func fetchData(code: String) {
        db.collection("conferences/\(code)/faqs")
            .order(by: "id", descending: false).addSnapshotListener { querySnapshot, error in
                guard let docs = querySnapshot?.documents else {
                    print("No Documents")
                    return
                }

                self.faqs = docs.compactMap { queryDocumentSnapshot -> FAQ? in
                    do {
                        return try queryDocumentSnapshot.data(as: FAQ.self)
                    } catch {
                        print("Error \(error)")
                        return nil
                    }
                }
                // NSLog("InfoViewModel: Documents: \(self.documents.count)")
            }
        db.collection("conferences/\(code)/articles")
            .order(by: "updated_at", descending: true).addSnapshotListener { querySnapshot, error in
                guard let docs = querySnapshot?.documents else {
                    print("No Documents")
                    return
                }

                self.news = docs.compactMap { queryDocumentSnapshot -> Article? in
                    do {
                        return try queryDocumentSnapshot.data(as: Article.self)
                    } catch {
                        print("Error \(error)")
                        return nil
                    }
                }
                // NSLog("InfoViewModel: Documents: \(self.documents.count)")
            }
    }
}
