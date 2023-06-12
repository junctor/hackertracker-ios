//
//  InfoViewModel.swift
//  hackertracker
//
//  Created by Seth W Law on 6/8/23.
//

import FirebaseFirestore
import Foundation
import SwiftUI

class InfoViewModel: ObservableObject {
    @Published var documents = [Document]()
    @Published var tagtypes = [TagType]()

    private var db = Firestore.firestore()

    func fetchData(code: String) {
        db.collection("conferences/\(code)/documents")
            .order(by: "id", descending: false).addSnapshotListener { querySnapshot, error in
                guard let docs = querySnapshot?.documents else {
                    print("No Documents")
                    return
                }

                self.documents = docs.compactMap { queryDocumentSnapshot -> Document? in
                    do {
                        return try queryDocumentSnapshot.data(as: Document.self)
                    } catch {
                        print("Error \(error)")
                        return nil
                    }
                }
                // NSLog("InfoViewModel: Documents: \(self.documents.count)")
            }
        db.collection("conferences/\(code)/tagtypes")
            .order(by: "sort_order", descending: false).addSnapshotListener { querySnapshot, error in
                guard let docs = querySnapshot?.documents else {
                    print("No Tags")
                    return
                }

                self.tagtypes = docs.compactMap { queryDocumentSnapshot -> TagType? in
                    do {
                        return try queryDocumentSnapshot.data(as: TagType.self)
                    } catch {
                        print("Error \(error)")
                        return nil
                    }
                }
            }
    }
}
